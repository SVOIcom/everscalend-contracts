pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract RepayModule is IRoles, IModule, IContractStateCache, IContractAddressSG, IRepayModule, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event RepayBorrow(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokenDelta);

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
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.REPAY_TOKENS;
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

    function updateCache(address tonWallet, mapping(uint32 => MarketInfo) _marketInfo, mapping(address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value , 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensReceived) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();

        IUAMUserAccount(userAccountManager).requestRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensReceived, marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function repayLoan(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 0);
        mapping(uint32 => MarketDelta) marketsDelta;
        MarketDelta marketDelta;

        uint256 tokensToRepay = borrowInfo.tokensBorrowed;
        uint256 tokensToReturn;
        uint256 tokenDelta;

        fraction ftokensToRepay = borrowInfo.tokensBorrowed.numFMul(marketInfo[marketId].index);
        ftokensToRepay = ftokensToRepay.fDiv(borrowInfo.index);
        tokensToRepay = ftokensToRepay.toNum();

        if (tokensToRepay <= tokensForRepay) {
            tokensToReturn = tokensForRepay - tokensToRepay;
            borrowInfo.tokensBorrowed = 0;
            borrowInfo.index = marketInfo[marketId].index;
            tokenDelta = tokensToRepay;
        } else {
            tokensToReturn = 0;
            borrowInfo.tokensBorrowed = tokensToRepay - tokensForRepay;
            borrowInfo.index = marketInfo[marketId].index;
            tokenDelta = tokensForRepay;
        }

        marketDelta.totalBorrowed.delta = tokenDelta;
        marketDelta.totalBorrowed.positive = false;
        marketDelta.realTokenBalance.delta = tokenDelta;
        marketDelta.realTokenBalance.positive = true;

        marketsDelta[marketId] = marketDelta;

        emit RepayBorrow(marketId, marketDelta, tonWallet, tokenDelta);

        TvmBuilder tb;
        tb.store(marketId);
        tb.store(tonWallet);
        tb.store(userTip3Wallet);
        tb.store(tokensToReturn);
        TvmBuilder borrowInfoStorage;
        borrowInfoStorage.store(borrowInfo);
        tb.store(borrowInfoStorage.toCell());

        IContractStateCacheRoot(marketAddress).receiveCacheDelta{
            flag: MsgFlag.REMAINING_GAS
        }(marketsDelta, tb.toCell());
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, address userTip3Wallet, uint256 tokensToReturn) = ts.decode(uint32, address, address, uint256);
        TvmSlice borrowInfoStorage = ts.loadRefAsSlice();
        (BorrowInfo borrowInfo) = borrowInfoStorage.decode(BorrowInfo);
        IUAMUserAccount(userAccountManager).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToReturn, borrowInfo);
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }
}