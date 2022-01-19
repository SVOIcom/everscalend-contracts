pragma ton-solidity >= 0.43.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import './interfaces/IMarketInterfaces.sol';
import "../ModulesForMarket/interfaces/IModule.sol";

contract MarketAggregator is IRoles, IUpgradableContract, IMarketOracle, IMarketSetters, IMarketOwnerFunctions, IMarketGetters, IMarketOperations, IContractStateCacheRoot {
    using UFO for uint256;
    using FPO for fraction;

    // Information for update
    uint32 public contractCodeVersion;

    address public userAccountManager;
    address public walletController;
    address public oracle;
    mapping(uint32 => bool) createdMarkets;
    mapping(address => uint32) tokensToMarkets;
    mapping(uint32 => MarketInfo) markets;
    mapping(address => fraction) tokenPrices;
    mapping(address => bool) realTokenRoots;

    mapping(uint8 => address) public modules;
    uint128 moduleAmount;
    mapping(address => bool) isModule;

    /*********************************************************************************************************/
    // Events

    event MarketCreated(uint32 marketId, MarketInfo marketState);
    event MarketDeleted(uint32 marketId, MarketInfo marketState);
    event LiquidationPossible(address tonWallet, fraction accountHealth);

    /*********************************************************************************************************/
    // Base functions - for deploying and upgrading contract
    // We are using Platform so constructor is not available
    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external canUpgrade {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            _owner,
            userAccountManager,
            walletController,
            oracle,
            markets,
            tokenPrices,
            modules,
            updateParams,
            codeVersion
        );
    }

    // mappings like createdMarkets, tokensToMarkets are derivatives from markets mapping and must be recreated
    function onCodeUpgrade(
        address owner,
        address _userAccountManager,
        address _walletController,
        address _oracle,
        mapping(uint32 => MarketInfo) _markets,
        mapping(address => fraction) _tokenPrices,
        mapping(uint8 => address) _modules,
        TvmCell,
        uint32 _codeVersion
    ) private {
        tvm.resetStorage();
        contractCodeVersion = _codeVersion;
        _owner = owner;
        userAccountManager = _userAccountManager;
        walletController = _walletController;
        oracle = _oracle;
        markets = _markets;
        tokenPrices = _tokenPrices;
        modules = _modules;
        moduleAmount = 0;
        for ((, address module): modules) {
            moduleAmount += 1;
            isModule[module] = true;
        }

        for ((uint32 marketId, MarketInfo market): markets) {
            createdMarkets[marketId] = true;
            tokensToMarkets[market.token] = marketId;
            realTokenRoots[market.token] = true;
        }
    }

    /*********************************************************************************************************/
    // Cache update functions

    function receiveCacheDelta(mapping(uint32 => MarketDelta) marketsDelta, TvmCell args) external override onlyModule {
        tvm.rawReserve(msg.value, 2);
        for ((uint32 marketId, MarketDelta marketDelta): marketsDelta) {
            _acquireInterest(marketId);
            _updateMarketDelta(marketId, marketDelta);
            _updateExchangeRate(marketId);
        }

        IModule(msg.sender).resumeOperation{
            flag: MsgFlag.REMAINING_GAS
        }(args, markets, tokenPrices);
    }

    // process: 
    // acquireInterest - to get deltas from time passing by....
    // update deltas - change real parameters
    // acquireInterest to update parameters - to update parameters such as exchange rate and etc

    function _updateAllMarkets() internal {
        for ((uint32 marketId,) : markets) {
            _acquireInterest(marketId);
            _updateExchangeRate(marketId);
        }
    }


    function _acquireInterest(uint32 marketId) internal {
        MarketInfo mi = markets[marketId];
        uint256 dt = now - mi.lastUpdateTime;
        if (
            (markets[marketId].realTokenBalance != 0 ) ||
            (markets[marketId].totalBorrowed != 0)
        ) {
            fraction borrowRate = MarketOperations.calculateBorrowInterestRate(mi.baseRate, mi.realTokenBalance, mi.totalBorrowed, mi.utilizationMultiplier);
            borrowRate = borrowRate.simplify();
            fraction simpleInterestFactor = borrowRate.fNumMul(dt);
            fraction newIndex = simpleInterestFactor.fNumAdd(1);
            newIndex = mi.index.fMul(newIndex);
            newIndex = newIndex.simplify();
            fraction finterestAccumulated = mi.totalBorrowed.numFMul(simpleInterestFactor);
            uint256 interestAccumulated = finterestAccumulated.toNum();
            fraction freservesDelta = interestAccumulated.numFMul(mi.reserveFactor);
            uint256 totalBorrowNew = mi.totalBorrowed + interestAccumulated;
            uint256 totalReservesNew = mi.totalReserve + freservesDelta.toNum();
            mi.index = newIndex;
            mi.totalBorrowed = totalBorrowNew;
            mi.totalReserve = totalReservesNew;
            markets[marketId] = mi;
        }
        markets[marketId].lastUpdateTime = now;
    }

    function _updateMarketDelta(uint32 marketId, MarketDelta marketDelta) internal {
        if (
            marketDelta.realTokenBalance.delta != 0 &&
            marketDelta.realTokenBalance.positive
        ) {
            markets[marketId].realTokenBalance += marketDelta.realTokenBalance.delta;
        } else {
            markets[marketId].realTokenBalance -= marketDelta.realTokenBalance.delta;
        }

        if (
            marketDelta.totalBorrowed.delta != 0 &&
            marketDelta.totalBorrowed.positive
        ) {
            markets[marketId].totalBorrowed += marketDelta.totalBorrowed.delta;
        } else {
            markets[marketId].totalBorrowed -= marketDelta.totalBorrowed.delta;
        }

        if (
            marketDelta.vTokenBalance.delta != 0 &&
            marketDelta.vTokenBalance.positive
        ) {
            markets[marketId].vTokenBalance += marketDelta.vTokenBalance.delta;
        } else {
            markets[marketId].vTokenBalance -= marketDelta.vTokenBalance.delta;
        }

        if (
            marketDelta.totalReserve.delta != 0 &&
            marketDelta.totalReserve.positive
        ) {
            markets[marketId].totalReserve += marketDelta.totalReserve.delta;
        } else {
            markets[marketId].totalReserve -= marketDelta.totalReserve.delta;
        }
    }

    function _updateExchangeRate(uint32 marketId) internal {
        if (markets[marketId].vTokenBalance != 0) {
            fraction exchangeRate = MarketOperations.calculateExchangeRate(
                markets[marketId].realTokenBalance,
                markets[marketId].totalBorrowed,
                markets[marketId].totalReserve,
                markets[marketId].vTokenBalance
            );
            markets[marketId].exchangeRate = exchangeRate;
        }
    }


    function updateModulesCache() external view override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        uint128 valueToTransfer = msg.value / (moduleAmount + 1);
        for ((, address module) : modules) {
            IContractStateCache(module).updateCache{
                value: valueToTransfer
            }(_owner, markets, tokenPrices);
        }
    }

    /*********************************************************************************************************/
    // Getters
    function getServiceContractAddresses() external override view responsible returns(address _userAccountManager, address _tip3WalletController, address _oracle) {
        return {flag: MsgFlag.REMAINING_GAS} (userAccountManager, walletController, oracle);
    }

    function getTokenPrices() external override view responsible returns(mapping(address => fraction)) {
        return {flag: MsgFlag.REMAINING_GAS} tokenPrices;
    }

    function getMarketInformation(uint32 marketId) external override view responsible returns(MarketInfo) {
        return {flag: MsgFlag.REMAINING_GAS} markets[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketInfo)) {
        return {flag: MsgFlag.REMAINING_GAS} markets;
    }

    function withdrawExtraTons(uint128 amount) external override onlyOwner {
        tvm.accept();
        address(_owner).transfer({flag: 1, value: amount});
    }

    function getAllModules() external override view responsible returns(mapping(uint8 => address)) {
        return {flag: MsgFlag.REMAINING_GAS} modules;
    }

    /*********************************************************************************************************/
    // Manage markets functions
    function createNewMarket(
        uint32 marketId, 
        address realToken,
        fraction _baseRate,
        fraction _utilizationMultiplier,
        fraction _reserveFactor,
        fraction _exchangeRate,
        fraction _collateralFactor,
        fraction _liquidationMultiplier
    ) external canChangeParams {
        tvm.rawReserve(msg.value, 2);
        if (!createdMarkets[marketId]) {
            createdMarkets[marketId] = true;
            
            fraction one = fraction({nom: 1, denom: 1});

            markets[marketId] = MarketInfo({
                token: realToken,
                realTokenBalance: 0,
                vTokenBalance: 0,
                totalBorrowed: 0,
                totalReserve: 0,

                index: one,
                baseRate: _baseRate,
                utilizationMultiplier: _utilizationMultiplier,
                reserveFactor: _reserveFactor,
                exchangeRate: _exchangeRate,
                collateralFactor: _collateralFactor,
                liquidationMultiplier: _liquidationMultiplier,

                lastUpdateTime: now
            });

            tokensToMarkets[realToken] = marketId;

            emit MarketCreated(marketId, markets[marketId]);
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function updateMarketParameters(
        uint32 marketId,
        fraction _baseRate,
        fraction _utilizationMultiplier,
        fraction _reserveFactor,
        fraction _exchangeRate,
        fraction _collateralFactor,
        fraction _liquidationMultiplier
    ) external canChangeParams {
        tvm.rawReserve(msg.value, 2);

        MarketInfo mi = markets[marketId];
        mi.baseRate = _baseRate;
        mi.utilizationMultiplier = _utilizationMultiplier;
        mi.reserveFactor = _reserveFactor;
        mi.collateralFactor = _collateralFactor;
        mi.liquidationMultiplier = _liquidationMultiplier;
        if (mi.vTokenBalance == 0) {
            mi.exchangeRate = _exchangeRate;
        }

        markets[marketId] = mi;
        MarketDelta marketDelta;

        _acquireInterest(marketId);
        _updateMarketDelta(marketId, marketDelta);
        _updateExchangeRate(marketId);

        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function removeMarket(
        uint32 marketId
    ) external canChangeParams {
        tvm.rawReserve(msg.value, 2);

        emit MarketDeleted(marketId, markets[marketId]);

        delete tokensToMarkets[markets[marketId].token];
        delete createdMarkets[marketId];
        delete markets[marketId];

        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Operations with modules

    function addModule(uint8 operationId, address module) external canChangeParams {
        tvm.rawReserve(msg.value, 2);
        modules[operationId] = module;
        isModule[module] = true;
        moduleAmount = moduleAmount + 1;
        IContractStateCache(module).updateCache{
            flag: MsgFlag.REMAINING_GAS
        }(_owner, markets, tokenPrices);
    }

    function removeModule(uint8 operationId) external canChangeParams {
        tvm.rawReserve(msg.value, 2);
        delete isModule[modules[operationId]];
        delete modules[operationId];
        moduleAmount = moduleAmount - 1;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performOperationWalletController(uint8 operationId, address tokenRoot, TvmCell args) external override view onlyWalletController {
        uint32 marketId = tokensToMarkets[tokenRoot];
        TvmCell payload = _createOperationUpdatePayload(operationId, marketId, args);
        _updateAllPrices(payload);
    }

    function performOperationUserAccountManager(uint8 operationId, uint32 marketId, TvmCell args) external override view onlyUserAccountManager {
        TvmCell payload = _createOperationUpdatePayload(operationId, marketId, args);
        _updateAllPrices(payload);
    }

    function performOperation(TvmCell args) internal view {
        TvmSlice ts = args.toSlice();

        uint8 operationId = ts.decode(uint8);
        if (operationId != OperationCodes.NO_OP) {
            uint32 marketId = ts.decode(uint32);
            TvmCell moduleArgs = ts.loadRef();
            IModule(modules[operationId]).performAction{
                flag: MsgFlag.REMAINING_GAS
            }(marketId, moduleArgs, markets, tokenPrices);
        } else {
            address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function calculateUserAccountHealth(
        address tonWallet, 
        address gasTo, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo, 
        TvmCell dataToTransfer
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        _updateAllMarkets();

        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        fraction accountHealth = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, markets, tokenPrices);

        if (accountHealth.nom < accountHealth.denom) {
            emit LiquidationPossible(tonWallet, accountHealth);
        }

        IUAMUserAccount(userAccountManager).updateUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, gasTo, accountHealth, updatedIndexes, dataToTransfer);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi) : markets) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function _createOperationUpdatePayload(uint8 operationId, uint32 marketId, TvmCell args) internal pure returns (TvmCell payload) {
        TvmBuilder tb;
        tb.store(operationId);
        tb.store(marketId);
        tb.storeRef(args);
        return tb.toCell();
    }

    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external override view onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        IWCMInteractions(walletController).transferTokensToWallet{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, markets[marketId].token, userTip3Wallet, toPayout);
    }

    /*********************************************************************************************************/
    // Interactions with oracle

    /**
     * @param tokenRoot Address of TIP-3 token root to update
     * @param payload Payload that will be passed during update and received after
     */
    function updatePrice(address tokenRoot, TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getTokenPrice{
            flag: MsgFlag.REMAINING_GAS,
            callback: this.receiveUpdatedPrice
        }(tokenRoot, payload);
    }

    /**
     * @param tokenRoot Address of updated TIP-3 token root
     * @param nom Nominator of token's price to usd
     * @param denom Denominator of token's price to usd
     */
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell) external override onlyOracle {
        tokenPrices[tokenRoot] = fraction(nom, denom);
    }

    /**
     * @param payload Payload that will be passed during update and received after
     */
    function _updateAllPrices(TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getAllTokenPrices{
            flag: MsgFlag.REMAINING_GAS,
            callback: this.receiveAllUpdatedPrices
        }(payload);
    }

    /**
     * @param updatedPrices Updated prices of all tokens that exist in oracle
     */
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external override onlyOracle {
        for((address t, MarketPriceInfo mpi): updatedPrices) {
            tokenPrices[t] = fraction(mpi.tokens, mpi.usd);
            tokenPrices[t] = tokenPrices[t].simplify();

            _updateAllMarkets();
        }

        performOperation(payload);
    }

    /**
     * @notice Owner can use this function to force update all prices
     */
    function forceUpdateAllPrices() external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        TvmBuilder tb;
        tb.store(OperationCodes.NO_OP);
        _updateAllPrices(tb.toCell());
    }

    /*********************************************************************************************************/
    // Setters
    /**
     * @param _userAccountManager Address of userAccountManager smart contract
     */
    function setUserAccountManager(address _userAccountManager) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param _tip3WalletController Address of TIP3WalletController smart contract
     */
    function setWalletController(address _tip3WalletController) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        walletController = _tip3WalletController;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param _oracle Address of Oracle smart contract
     */
    function setOracleAddress(address _oracle) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        oracle = _oracle;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Modificators

    modifier onlySelf() {
        require(msg.sender == address(this), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_SELF);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ORACLE);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_USER_ACCOUNT_MANAGER);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyWalletController() {
        require(msg.sender == walletController, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_WALLET_CONTROLLER);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyRealTokenRoot() {
        require(realTokenRoots.exists(msg.sender));
        _;
    }

    modifier onlyModule() {
        require(isModule.exists(msg.sender));
        _;
    }

    modifier onlyExecutor() {
        require(
            (msg.sender == userAccountManager) ||
            (isModule.exists(msg.sender))
        );
        _;
    }
}