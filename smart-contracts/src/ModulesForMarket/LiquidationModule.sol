pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract LiquidationModule is ACModule, ILiquidationModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    event TokensLiquidated(uint32 marketId, MarketDelta marketDelta1, uint32 marketToLiquidate, MarketDelta marketDelta2, address liquidator, address targetUser, uint256 tokensLiquidated, uint256 vTokensSeized);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
        actionId = OperationCodes.LIQUIDATE_TOKENS;
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
        actionId = OperationCodes.LIQUIDATE_TOKENS;
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    // Locking module for USER instead of global lock so no one can mess with double spending from target userAccount
    // It must be unlocked using callback after operation is finished (tokens are seized and transferred to liquidator)
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address targetUser, address tip3UserWallet) = ts.decode(address, address, address);
        TvmSlice amountTS = ts.loadRefAsSlice();
        (uint32 marketToLiquidate, uint256 tokenAmount) = amountTS.decode(uint32, uint256);
        if (!_isUserLocked(targetUser)) {
            _lockUser(targetUser, true);
            mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
            IUAMUserAccount(userAccountManager).requestLiquidationInformation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokenAmount, updatedIndexes);
        } else {
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(
                tonWallet, tip3UserWallet, marketId, tokenAmount
            );
        }
    }

    function liquidate(
        address tonWallet, 
        address targetUser, 
        address tip3UserWallet, 
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 tokensProvided, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        // Liquidation:
        // 1. Calculate user account health to check if liquidation is required
        // 2. Calculate max values
        // 3. Choose minimal value of all max values
        // 4. Based on min value calculate rest of parameters, it is guaranteed that:
        // - User will not exceed tokens that he provided for liquidation (providingLimit)
        // - User will not exceed tokens that are available for liquidation (borrowLimit)
        // - User will not exceed vToken balance of user that is liquidated (vTokenLimit)

        // New Liquidation:
        // Instead of using reserves -> use only user's cash to pay for liquidation
        // Explanation:
        // In previous version it was more profitable for liquidators to wait until user's debt become too high
        // To get tokens that are stored in reserves
        // Now they need to liquidate user as soon as possible in other scenario they will not get anything

        fraction health = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);
        if (health.nom <= health.denom) {
            uint256 tokensToLiquidate = math.min(
                borrowInfo[marketId].tokensBorrowed,
                tokensProvided
            );

            // Calculating USD value of liquidation
            fraction ftokensToLiquidateUSD = tokensToLiquidate.numFMul(marketInfo[marketId].liquidationMultiplier);
            ftokensToLiquidateUSD = ftokensToLiquidateUSD.fDiv(tokenPrices[marketInfo[marketId].token]);

            // Calculating USD value of collateral
            fraction fvTokensCollateralUSD = supplyInfo[marketToLiquidate].numFMul(marketInfo[marketToLiquidate].exchangeRate);
            fvTokensCollateralUSD = fvTokensCollateralUSD.fDiv(tokenPrices[marketInfo[marketToLiquidate].token]);

            uint256 tokensToSeize;
            uint256 tokensToReturn;

            // Calculating how much of collateral tokens to seize
            fraction fvTokensCollateral = fvTokensCollateralUSD.getMin(ftokensToLiquidateUSD);
            fraction ftokensToSeize = fvTokensCollateral.fMul(tokenPrices[marketInfo[marketToLiquidate].token]);
            ftokensToSeize = ftokensToSeize.fDiv(marketInfo[marketToLiquidate].exchangeRate);
            tokensToSeize = ftokensToSeize.toNum();
            tokensToSeize = math.min(tokensToSeize, supplyInfo[marketToLiquidate]);

            tokensToReturn = tokensProvided - tokensToLiquidate;
            mapping(uint32 => MarketDelta) marketDeltas;
            MarketDelta collateralMarketDelta;
            MarketDelta liquidationMarketDelta;

            liquidationMarketDelta.totalBorrowed.delta = tokensToLiquidate;
            liquidationMarketDelta.totalBorrowed.positive = false;
            liquidationMarketDelta.realTokenBalance.delta = tokensToLiquidate;
            liquidationMarketDelta.realTokenBalance.positive = true;

            marketDeltas[marketId] = liquidationMarketDelta;
            marketDeltas[marketToLiquidate] = collateralMarketDelta;

            emit TokensLiquidated(marketId, liquidationMarketDelta, marketToLiquidate, collateralMarketDelta, tonWallet, targetUser, tokensToLiquidate, tokensToSeize);

            BorrowInfo userBorrowInfo = BorrowInfo(borrowInfo[marketId].tokensBorrowed - tokensToLiquidate, marketInfo[marketId].index);

            TvmBuilder tb;
            TvmBuilder addressStorage;
            addressStorage.store(tonWallet);
            addressStorage.store(targetUser);
            addressStorage.store(tip3UserWallet);
            TvmBuilder valueStorage;
            valueStorage.store(marketId);
            valueStorage.store(marketToLiquidate);
            valueStorage.store(tokensToSeize);
            valueStorage.store(tokensToReturn);
            TvmBuilder borrowInfoStorage;
            borrowInfoStorage.store(userBorrowInfo);
            tb.store(addressStorage.toCell());
            tb.store(valueStorage.toCell());
            tb.store(borrowInfoStorage.toCell());

            IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                flag: MsgFlag.REMAINING_GAS
            }(marketDeltas, tb.toCell());
        } else {
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(
                tonWallet, tip3UserWallet, marketId, tokensProvided
            );
        }
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        TvmSlice ts = args.toSlice();
        TvmSlice addressStorage = ts.loadRefAsSlice();
        (address tonWallet, address targetUser, address tip3UserWallet) = addressStorage.decode(address, address, address);
        TvmSlice valueStorage = ts.loadRefAsSlice();
        (uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn) = valueStorage.decode(uint32, uint32, uint256, uint256);
        TvmSlice borrowInfoStorage = ts.loadRefAsSlice();
        (BorrowInfo borrowInfo) = borrowInfoStorage.decode(BorrowInfo);
        IUAMUserAccount(userAccountManager).seizeTokens{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokensToSeize, tokensToReturn, borrowInfo);
    }

    function unlock(address addressToUnlock, TvmCell args) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        _lockUser(addressToUnlock, false);
        TvmSlice ts = args.toSlice();
        (address returnTonTo) = ts.decode(address);
        address(returnTonTo).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }
    // TODO: add callback for unlocking user after performing operation
}