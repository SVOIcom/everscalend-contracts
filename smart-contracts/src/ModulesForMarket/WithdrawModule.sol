pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract WithdrawModule is IRoles, IModule, IContractStateCache, IContractAddressSG, IWithdrawModule, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event TokenWithdraw(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 vTokensWithdrawn, uint256 realTokensWithdrawn);

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
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.WITHDRAW_TOKENS;
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
        TvmSlice ts = args.toSlice();
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        (address tonWallet, address userTip3Wallet, uint256 tokensToWithdraw) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToWithdraw, marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) supplyInfo,
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        MarketDelta marketDelta;
        mapping(uint32 => MarketDelta) marketsDelta;

        MarketInfo mi = marketInfo[marketId];

        // For token withdraw:
        // 1. Calculate account health
        // 2. Calculate USD amount for withdraw token
        // 3. Check if user can afford to withdraw required amount of real tokens

        fraction accountHealth = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);

        fraction fTokensToSend = tokensToWithdraw.numFMul(mi.exchangeRate);
        fraction fTokensToSendUSD = fTokensToSend.fDiv(tokenPrices[marketInfo[marketId].token]);

        // Check user balance in tokens just in case
        // There will be lock at user account for operation, unified for all operations
        // As all operations are finished with account health check, account will unlock after
        // Updating indexes
        if (
            (accountHealth.nom > accountHealth.denom) &&
            (supplyInfo[marketId] >= tokensToWithdraw)
        ) {
            if (
                accountHealth.nom - accountHealth.denom >= fTokensToSendUSD.toNum() &&
                fTokensToSend.toNum() <= mi.realTokenBalance - mi.totalReserve
            ) {
                uint256 tokensToSend = fTokensToSend.toNum();

                marketDelta.realTokenBalance.delta = tokensToSend;
                marketDelta.realTokenBalance.positive = false;
                marketDelta.vTokenBalance.delta = tokensToWithdraw;
                marketDelta.vTokenBalance.positive = false;

                marketsDelta[marketId] = marketDelta;

                emit TokenWithdraw(marketId, marketDelta, tonWallet, tokensToWithdraw, tokensToSend);

                TvmBuilder tb;
                tb.store(marketId);
                tb.store(tonWallet);
                tb.store(userTip3Wallet);
                TvmBuilder valueStorate;
                valueStorate.store(tokensToWithdraw);
                valueStorate.store(tokensToSend);
                tb.store(valueStorate.toCell());

                IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                    flag: MsgFlag.REMAINING_GAS
                }(marketsDelta, tb.toCell());
            } else {
                IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet);
            }
        } else {
            IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet);
        }
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, address userTip3Wallet) = ts.decode(uint32, address, address);
        TvmSlice values = ts.loadRefAsSlice();
        (uint256 tokensToWithdraw, uint256 tokensToSend) = values.decode(uint256, uint256);
        IUAMUserAccount(userAccountManager).writeWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }
}