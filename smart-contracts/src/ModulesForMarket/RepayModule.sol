pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract RepayModule is ACModule, IRepayModule, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;

    event RepayBorrow(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokenDelta);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
        actionId = OperationCodes.REPAY_TOKENS;
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
        actionId = OperationCodes.REPAY_TOKENS;
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function unlock(address, TvmCell) external override onlyOwner {}

    // Ok without locking, as no tokens are leaving contract, can only deposit
    // Coefficients will be rebalanced in MarketsAggregator
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensReceived) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();

        IUAMUserAccount(userAccountManager).requestRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensReceived, marketId, updatedIndexes);
    }

    function repayLoan(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
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
        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, address userTip3Wallet, uint256 tokensToReturn) = ts.decode(uint32, address, address, uint256);
        TvmSlice borrowInfoStorage = ts.loadRefAsSlice();
        (BorrowInfo borrowInfo) = borrowInfoStorage.decode(BorrowInfo);
        IUAMUserAccount(userAccountManager).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToReturn, borrowInfo);
    }
}