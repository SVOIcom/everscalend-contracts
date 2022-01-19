pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract LiquidationModule is IRoles, IModule, IContractStateCache, IContractAddressSG, ILiquidationModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event TokensLiquidated(uint32 marketId, mapping(uint32 => MarketDelta) marketDeltas, address liquidator, address targetUser, uint256 tokensLiquidated, uint256 vTokensSeized);

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
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.LIQUIDATE_TOKENS;
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
        (address tonWallet, address targetUser, address tip3UserWallet) = ts.decode(address, address, address);
        TvmSlice amountTS = ts.loadRefAsSlice();
        (uint32 marketToLiquidate, uint256 tokenAmount) = amountTS.decode(uint32, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).requestLiquidationInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokenAmount, updatedIndexes);
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
            uint256 tokensFromReserve;

            // Calculating how much of collateral tokens to seize
            fraction fvTokensCollateral = fvTokensCollateralUSD.getMin(ftokensToLiquidateUSD);
            fraction ftokensToSeize = fvTokensCollateral.fMul(tokenPrices[marketInfo[marketToLiquidate].token]);
            ftokensToSeize = ftokensToSeize.fDiv(marketInfo[marketToLiquidate].exchangeRate);
            tokensToSeize = ftokensToSeize.toNum();

            tokensToReturn = tokensProvided - tokensToLiquidate;
            mapping(uint32 => MarketDelta) marketDeltas;
            MarketDelta collateralMarketDelta;
            MarketDelta liquidationMarketDelta;

            liquidationMarketDelta.totalBorrowed.delta = tokensToLiquidate;
            liquidationMarketDelta.totalBorrowed.positive = false;
            liquidationMarketDelta.realTokenBalance.delta = tokensToLiquidate;
            liquidationMarketDelta.realTokenBalance.positive = true;

            if (fvTokensCollateralUSD.lessThan(ftokensToLiquidateUSD)) {
                // Using reserves from market to compensate liquidity absence
                fraction freservesUsageUSD = ftokensToLiquidateUSD.fSub(fvTokensCollateralUSD);
                freservesUsageUSD = freservesUsageUSD.simplify();
                fraction freservesUsageTokens = freservesUsageUSD.fMul(tokenPrices[marketInfo[marketToLiquidate].token]);
                uint256 reservesUsageTokens = freservesUsageTokens.toNum();
                if (reservesUsageTokens < marketInfo[marketId].totalReserve) {
                    tokensFromReserve = reservesUsageTokens;
                    collateralMarketDelta.totalReserve.delta = tokensFromReserve;
                    collateralMarketDelta.totalReserve.positive = false;
                } else {
                    // abort liquidation
                    IUAMUserAccount(userAccountManager).requestTokenPayout{
                        flag: MsgFlag.REMAINING_GAS
                    }(
                        tonWallet, tip3UserWallet, marketId, tokensProvided
                    );
                    tvm.exit();
                }
            }

            marketDeltas[marketId] = liquidationMarketDelta;
            marketDeltas[marketToLiquidate] = collateralMarketDelta;

            emit TokensLiquidated(marketId, marketDeltas, tonWallet, targetUser, tokensToLiquidate, tokensToSeize);

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
            valueStorage.store(tokensFromReserve);
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
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        TvmSlice addressStorage = ts.loadRefAsSlice();
        (address tonWallet, address targetUser, address tip3UserWallet) = addressStorage.decode(address, address, address);
        TvmSlice valueStorage = ts.loadRefAsSlice();
        (uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn, uint256 tokensFromReserve) = valueStorage.decode(uint32, uint32, uint256, uint256, uint256);
        TvmSlice borrowInfoStorage = ts.loadRefAsSlice();
        (BorrowInfo borrowInfo) = borrowInfoStorage.decode(BorrowInfo);
        IUAMUserAccount(userAccountManager).seizeTokens{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokensToSeize, tokensToReturn, tokensFromReserve, borrowInfo);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
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