pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IWalletControllerMarketInteractions.sol";
import "./interfaces/IWalletControllerMarketManagement.sol";
import "./interfaces/IWalletControllerGetters.sol";

import "./libraries/CostConstants.sol";
import "./libraries/WalletControllerErrorCodes.sol";
import "./libraries/OperationCodes.sol";

// import "../Market/interfaces/IMarketInterfaces.sol";
import "../Market/MarketsAggregator.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/TIP3/interfaces/ITokensReceivedCallback.sol";

import "../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../utils/TIP3/interfaces/ITONTokenWallet.sol";

import "../utils/libraries/MsgFlag.sol";

import { IRoles } from '../utils/interfaces/IRoles.sol';

contract WalletController is IRoles, IWCMInteractions, IWalletControllerMarketManagement, IWalletControllerGetters, IUpgradableContract, ITokensReceivedCallback {
    // Information for update
    uint32 public contractCodeVersion;

    address public marketAddress;

    // Root TIP-3 to market address mapping
    mapping (address => address) public wallets;
    mapping (address => bool) public realTokenRoots;
    mapping (address => bool) public vTokenRoots;
    mapping (address => uint32) public tokensToMarkets;

    mapping (uint32 => MarketTokenAddresses) public marketTIP3Info;

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    constructor(address _newOwner) public { 
        tvm.accept();
        _owner = _newOwner;
     } // Contract will be deployed using platform

    /*  Upgrade data for version 1 (from 0):
        bits:
            address root
            uint8 platformType
        refs:
            1. TvmCell platformCode
            2. mappingStorage:
                refs:
                    1. mapping(address => MarketTokenAddresses) marketAddresses
                    2. mapping(address => address) wallets
     */
    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion New code version
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external canUpgrade {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);
        
        onCodeUpgrade(
            _owner,
            marketAddress,
            wallets,
            realTokenRoots,
            vTokenRoots,
            marketTIP3Info,
            updateParams,
            codeVersion
        );
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
            2. initialData
            bits: 
                1. marketAddress
     */
    function onCodeUpgrade(
        address owner, 
        address _marketAddress, 
        mapping(address => address) _wallets, 
        mapping(address => bool) _realTokensRoots, 
        mapping(address => bool) _vTokenRoots, 
        mapping(uint32 => MarketTokenAddresses) _marketTIP3Info, 
        TvmCell, 
        uint32 _codeVersion
    ) private {
        tvm.accept();
        tvm.resetStorage();
        _owner = owner;
        marketAddress = _marketAddress;
        wallets = _wallets;
        realTokenRoots = _realTokensRoots;
        vTokenRoots = _vTokenRoots;
        marketTIP3Info = _marketTIP3Info;
        contractCodeVersion = _codeVersion;
    }

    /*********************************************************************************************************/
    // Market functions
    function setMarketAddress(address _market) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _market;

        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function addMarket(uint32 marketId, address realTokenRoot) external override canChangeParams {
        tvm.accept();
        marketTIP3Info[marketId] = MarketTokenAddresses({
            realToken: realTokenRoot,
            realTokenWallet: address.makeAddrStd(0, 0)
        });

        realTokenRoots[realTokenRoot] = true;

        wallets[realTokenRoot] = address.makeAddrStd(0, 1);

        tokensToMarkets[realTokenRoot] = marketId;

        addWallet(realTokenRoot);
    }

    /**
     * @param marketId Id of market to remove
     */
    function removeMarket(uint32 marketId) external override canChangeParams {
        tvm.accept();
        MarketTokenAddresses marketTokenAddresses = marketTIP3Info[marketId];

        delete wallets[marketTokenAddresses.realToken];
        delete realTokenRoots[marketTokenAddresses.realToken];
        delete tokensToMarkets[marketTokenAddresses.realToken];
        delete marketTIP3Info[marketId];
    }

    function transferTokensToWallet(address tonWallet, address tokenRoot, address userTip3Wallet, uint256 toPayout) external override view onlyTrusted {
        TvmCell empty;
        _transferTokensToWallet(tonWallet, tokenRoot, userTip3Wallet, uint128(toPayout), empty);
    }

    function _transferTokensToWallet(address tonWallet, address tokenRoot, address userTip3Wallet, uint128 toTransfer, TvmCell payload) internal view {
        ITONTokenWallet(wallets[tokenRoot]).transfer{
            flag: MsgFlag.REMAINING_GAS
        }(
            userTip3Wallet,
            toTransfer,
            0,
            tonWallet,
            true,
            payload
        );
    }

    /*********************************************************************************************************/
    // Wallet functionality
    /**
     * @param tokenRoot Address of token root to request wallet deploy
     */
    function addWallet(address tokenRoot) private pure {
        IRootTokenContract(tokenRoot).deployEmptyWallet{
            value: WCCostConstants.WALLET_DEPLOY_COST
        }(
            WCCostConstants.WALLET_DEPLOY_GRAMS,
            0,
            address(this),
            address(this)
        );

        IRootTokenContract(tokenRoot).getWalletAddress{
            value: WCCostConstants.GET_WALLET_ADDRESS,
            callback: this.receiveTIP3WalletAddress
        }(
            0,
            address(this)
        );
    }

    /**
     * @param _wallet Receive deployed wallet address
     */
    function receiveTIP3WalletAddress(address _wallet) external onlyExisingTIP3Root(msg.sender) {
        tvm.accept();

        wallets[msg.sender] = _wallet;
        uint32 marketId = tokensToMarkets[msg.sender];
        marketTIP3Info[marketId].realTokenWallet = _wallet;
        this.setReceiveCallback(_wallet);
    }

    function setReceiveCallback(address _wallet) external {
        require(msg.sender == address(this));
        tvm.accept();

        ITONTokenWallet(_wallet).setReceiveCallback{
            value: WCCostConstants.SET_RECEIVE_CALLBACK
        }(
            address(this),
            true
        );
    }

    function tokensReceivedCallback(
        address token_wallet,
        address token_root,
        uint128 amount,
        uint256, // sender_public_key,
        address sender_address,
        address sender_wallet,
        address, // original_gas_to,
        uint128, // updated_balance,
        TvmCell payload
    ) external override onlyOwnWallet(token_root, msg.sender) 
    {
        tvm.rawReserve(msg.value, 2);
            TvmSlice ts = payload.toSlice();
        if (
            ts.bits() == 8 &&
            ts.refs() == 1
        ) {
            uint8 operation = ts.decode(uint8);
            TvmSlice args = ts.loadRefAsSlice();
            if (operation == OperationCodes.SUPPLY_TOKENS) {
                TvmBuilder tb;
                tb.store(sender_address);
                tb.store(uint256(amount));
                MarketAggregator(marketAddress).performOperationWalletController{
                    flag: MsgFlag.REMAINING_GAS
                }(operation, token_root, tb.toCell());
            } else if (operation == OperationCodes.REPAY_TOKENS) {
                TvmBuilder tb;
                tb.store(sender_address);
                tb.store(sender_wallet);
                tb.store(uint256(amount));
                MarketAggregator(marketAddress).performOperationWalletController{
                    flag: MsgFlag.REMAINING_GAS
                }(operation, token_root, tb.toCell());
            } else if (operation == OperationCodes.LIQUIDATE_TOKENS) {
                (address targetUser, uint32 marketToLiquidate) = args.decode(address, uint32);
                TvmBuilder tb;
                TvmBuilder amountStorage;
                tb.store(sender_address);
                tb.store(targetUser);
                tb.store(sender_wallet);
                amountStorage.store(marketToLiquidate);
                amountStorage.store(uint256(amount));
                tb.store(amountStorage.toCell());
                MarketAggregator(marketAddress).performOperationWalletController{
                    flag: MsgFlag.REMAINING_GAS
                }(operation, token_root, tb.toCell());
            } else {
                _transferTokensToWallet(sender_address, token_root, sender_wallet, amount, payload);
            }
        } else {
            _transferTokensToWallet(sender_address, token_root, sender_wallet, amount, payload);
        }
    }
    
    /*********************************************************************************************************/
    // Getter functions
    function getRealTokenRoots() external override view responsible returns(mapping(address => bool)) {
        return {flag: MsgFlag.REMAINING_GAS} realTokenRoots;
    }

    function getWallets() external override view responsible returns(mapping(address => address)) {
        return {flag: MsgFlag.REMAINING_GAS} wallets;
    }

    function getMarketAddresses(uint32 marketId) external override view responsible returns(MarketTokenAddresses) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketTokenAddresses)) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info;
    }

    /*********************************************************************************************************/
    // modifiers

    modifier onlyMarket() {
        require(msg.sender == marketAddress, WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_MARKET);
        _;
    }

    modifier onlyTrusted() {
        require(
            (msg.sender == marketAddress)
        );
        _;
    }

    /**
     * @param tokenRoot Root address of TIP-3 token
     * @param tokenWallet Address of TIP-3 wallet
     */
    modifier onlyOwnWallet(address tokenRoot, address tokenWallet) {
        require(wallets[tokenRoot] == tokenWallet, WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWN_WALLET);
        _;
    }

    /**
     * @param rootAddress msg.sender parameter
     */
    modifier onlyExisingTIP3Root(address rootAddress) {
        require(wallets.exists(rootAddress), WalletControllerErrorCodes.ERROR_TIP3_ROOT_IS_UNKNOWN);
        _;
    }

    /*********************************************************************************************************/
    // Functions for payload creation

    function createSupplyPayload() external override pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.SUPPLY_TOKENS);
        TvmBuilder op;
        tb.store(op.toCell());

        return tb.toCell();
    }

    function createRepayPayload() external override pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.REPAY_TOKENS);
        TvmBuilder op;
        tb.store(op.toCell());

        return tb.toCell();
    }

    function createLiquidationPayload(address targetUser, uint32 marketId) external override pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.LIQUIDATE_TOKENS);
        TvmBuilder op;
        op.store(targetUser);
        op.store(marketId);
        tb.store(op.toCell());

        return tb.toCell();
    }
}
