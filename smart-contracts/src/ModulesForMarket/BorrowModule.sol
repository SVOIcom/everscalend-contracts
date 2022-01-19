pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract BorrowModule is IRoles, IModule, IContractStateCache, IContractAddressSG, IBorrowModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event TokenBorrow(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokensBorrowed);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external override canUpgrade {
        tvm.rawReserve(msg.value, 2);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade (
            _owner,
            marketAddress,
            userAccountManager,
            marketInfo,
            tokenPrices,
            codeVersion
        );
    }

    function onCodeUpgrade(
        address owner,
        address _marketAddress,
        address _userAccountManager,
        mapping(uint32 => MarketInfo) _marketInfo,
        mapping(address => fraction) _tokenPrices,
        uint32 _codeVersion
    ) private {
        tvm.accept();
        tvm.resetStorage();
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.BORROW_TOKENS;
    }

    function getModuleState() external override view returns(mapping(uint32 => MarketInfo), mapping(address => fraction)) {
        return(marketInfo, tokenPrices);
    }

    function setMarketAddress(address _marketAddress) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _marketAddress;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setUserAccountManager(address _userAccountManager) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function getContractAddresses() external override view responsible returns(address _owner, address _marketAddress, address _userAccountManager) {
        return {flag: MsgFlag.REMAINING_GAS} (_owner, marketAddress, userAccountManager);
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).updateUserIndexes{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        mapping(uint32 => MarketDelta) marketsDelta;
        MarketDelta marketDelta;
        
        // Borrow:
        // 1. Check that market has enough tokens for lending
        // 2. Calculate user account health
        // 3. Calculate USD value of tokens to borrow
        // 4. Check if there is enough (collateral - borrowed) for new token borrow
        // 5. Increase user's borrowed amount

        if (tokensToBorrow < marketInfo[marketId].realTokenBalance - marketInfo[marketId].totalReserve) {
            fraction accountHealth = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);
            if (accountHealth.nom > accountHealth.denom) {
                uint256 healthDelta = accountHealth.nom - accountHealth.denom;
                fraction tmp = healthDelta.numFMul(tokenPrices[marketInfo[marketId].token]);
                uint256 possibleTokenWithdraw = tmp.toNum();
                if (possibleTokenWithdraw >= tokensToBorrow) {
                    marketDelta.totalBorrowed.delta = tokensToBorrow;
                    marketDelta.totalBorrowed.positive = true;
                    marketDelta.realTokenBalance.delta = tokensToBorrow;
                    marketDelta.realTokenBalance.positive = false;

                    marketsDelta[marketId] = marketDelta;

                    TvmBuilder tb;
                    tb.store(marketId);
                    tb.store(tonWallet);
                    tb.store(userTip3Wallet);
                    tb.store(tokensToBorrow);

                    emit TokenBorrow(marketId, marketDelta, tonWallet, tokensToBorrow);

                    IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                        flag: MsgFlag.REMAINING_GAS
                    }(marketsDelta, tb.toCell());
                } else {
                    IUAMUserAccount(userAccountManager).writeBorrowInformation{
                        flag: MsgFlag.REMAINING_GAS
                    }(tonWallet, userTip3Wallet, 0, marketId, marketInfo[marketId].index);
                }
            } else {
                IUAMUserAccount(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, 0, marketId, marketInfo[marketId].index);
            }
        } else {
            address(tonWallet).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(uint32, address, address, uint256);
        IUAMUserAccount(userAccountManager).writeBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, marketInfo[marketId].index);
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}