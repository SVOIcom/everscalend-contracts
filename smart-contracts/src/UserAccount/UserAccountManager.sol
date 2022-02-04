pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";
import "./interfaces/IUAMUserAccount.sol";
import "./interfaces/IUAMMarket.sol";

import "./libraries/UserAccountErrorCodes.sol";
import './libraries/CostConstants.sol';

import "../Market/interfaces/IMarketInterfaces.sol";

import "../WalletController/libraries/OperationCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

import './UserAccount.sol';

import '../ModulesForMarket/interfaces/IModule.sol';

contract UserAccountManager is IRoles, IUpgradableContract, IUserAccountManager, IUAMUserAccount, IUAMMarket {
    // Information for update
    uint32 public contractCodeVersion;

    address public marketAddress;
    mapping(uint8 => address) public modules;
    mapping(address => bool) public existingModules;
    mapping(uint32 => TvmCell) public userAccountCodes;

    event AccountCreated(address tonWallet, address userAddress);

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    // Contract is deployed via platform
    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
    }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
            uint32 codeVersion
        refs:
            1. platformCode
            2. additionalData:
            bits:
                1. address marketAddress
            refs:
                1. mapping(uint32 => bool) marketIds
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external canUpgrade {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            _owner,
            marketAddress,
            modules,
            existingModules,
            userAccountCodes,
            updateParams,
            codeVersion
        );
    }

    function onCodeUpgrade(
        address owner,
        address _marketAddress,
        mapping(uint8 => address) _modules,
        mapping(address => bool) _existingModules,
        mapping(uint32 => TvmCell) _userAccountCodes,
        TvmCell,
        uint32 _codeVersion
    ) private {
        tvm.accept();
        tvm.resetStorage();
        contractCodeVersion = _codeVersion;
        _owner = owner;
        marketAddress = _marketAddress;
        modules = _modules;
        existingModules = _existingModules;
        userAccountCodes = _userAccountCodes;
    }

    /*********************************************************************************************************/
    // Functions for user account
    /**
     * @param tonWallet Address of user's ton wallet
     */
    function createUserAccount(address tonWallet) external override view {
        TvmSlice ts = userAccountCodes[0].toSlice();
        require(!ts.empty());

        address userAccount = new UserAccount{
            value: UserAccountCostConstants.useForUADeploy,
            code: userAccountCodes[0],
            pubkey: 0,
            varInit: {
                owner: tonWallet
            }
        }();

        emit AccountCreated(tonWallet, userAccount);

        _updateUserAccount(tonWallet);
    }

    // address calculation functions
    /**
     * @param tonWallet Address of user's ton wallet
     */
    function calculateUserAccountAddress(address tonWallet) external override responsible view returns (address) {
        return { value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED } _calculateUserAccountAddress(tonWallet);
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    function _calculateUserAccountAddress(address tonWallet) internal view returns(address) {
        return address(tvm.hash(_buildUserAccountData(tonWallet)));
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    function _buildUserAccountData(address tonWallet) private view returns (TvmCell data) {
        return tvm.buildStateInit({
            contr: UserAccount,
            varInit: {
                owner: tonWallet
            },
            pubkey: 0,
            code: userAccountCodes[0]
        });
    }

    /*********************************************************************************************************/
    // Supply operations

    function writeSupplyInfo(
        address tonWallet,
        uint32 marketId, 
        uint256 tokensToSupply, 
        fraction index
    ) external override view onlyModule(OperationCodes.SUPPLY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeSupplyInfo{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(marketId, tokensToSupply, index);
    }

    /*********************************************************************************************************/
    // Withdraw operations

    function requestWithdraw(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToWithdraw
    ) external override view onlyValidUserAccount(tonWallet) {
        TvmBuilder tb;
        tb.store(tonWallet);
        tb.store(userTip3Wallet);
        tb.store(tokensToWithdraw);
        IMarketOperations(marketAddress).performOperationUserAccountManager{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(OperationCodes.WITHDRAW_TOKENS, marketId, tb.toCell());
    }

    function requestWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.WITHDRAW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).requestWithdrawInfo{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(userTip3Wallet, marketId, tokensToWithdraw, updatedIndexes);
    }

    function receiveWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw,
        uint32 marketId,
        mapping(uint32 => uint256) supplyInfo,
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override view onlyValidUserAccount(tonWallet) {
        IWithdrawModule(modules[OperationCodes.WITHDRAW_TOKENS]).withdrawTokensFromMarket{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, userTip3Wallet, tokensToWithdraw, marketId, supplyInfo, borrowInfo);
    }

    function writeWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToWithdraw, 
        uint256 tokensToSend
    ) external override view onlyModule(OperationCodes.WITHDRAW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet); 
        IUserAccountData(userAccount).writeWithdrawInfo{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
    }

    /*********************************************************************************************************/
    // Borrow operations

    function requestIndexUpdate(
        address tonWallet, 
        uint32 marketId, 
        TvmCell args
    ) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).performOperationUserAccountManager{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(OperationCodes.BORROW_TOKENS, marketId, args);
    }

    function updateUserIndexes(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensToBorrow, 
        uint32 marketId,
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.BORROW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).borrowUpdateIndexes{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(marketId, updatedIndexes, userTip3Wallet, tokensToBorrow);
    }

    function passBorrowInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToBorrow, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override view onlyValidUserAccount(tonWallet) {
        IBorrowModule(modules[OperationCodes.BORROW_TOKENS]).borrowTokensFromMarket{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, supplyInfo, borrowInfo);
    }

    function writeBorrowInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensToBorrow, 
        uint32 marketId, 
        fraction index
    ) external override view onlyModule(OperationCodes.BORROW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeBorrowInformation{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(marketId, tokensToBorrow, userTip3Wallet, index);
    }

    /*********************************************************************************************************/
    // Repay operations

    function requestRepayInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensForRepay, 
        uint32 marketId,
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.REPAY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).sendRepayInfo{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(userTip3Wallet, marketId, tokensForRepay, updatedIndexes);
    }

    function receiveRepayInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external override view onlyValidUserAccount(tonWallet) {
        IRepayModule(modules[OperationCodes.REPAY_TOKENS]).repayLoan{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, userTip3Wallet, tokensForRepay, marketId, borrowInfo);
    }

    function writeRepayInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId,
        uint256 tokensToReturn, 
        BorrowInfo bi
    ) external override view onlyModule(OperationCodes.REPAY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeRepayInformation{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(userTip3Wallet, marketId, tokensToReturn, bi);
    }

    /*********************************************************************************************************/
    // Liquidation

    function requestLiquidationInformation(
        address tonWallet, 
        address targetUser, 
        address tip3UserWallet, 
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 tokensProvided,
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.LIQUIDATE_TOKENS) {
        address userAccount = _calculateUserAccountAddress(targetUser);
        IUserAccountData(userAccount).requestLiquidationInformation{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, tip3UserWallet, marketId, marketToLiquidate, tokensProvided, updatedIndexes);
    }

    function receiveLiquidationInformation(
        address tonWallet, 
        address targetUser, 
        address tip3UserWallet, 
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 tokensProvided, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override view onlyValidUserAccount(targetUser) {
        ILiquidationModule(modules[OperationCodes.LIQUIDATE_TOKENS]).liquidate{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokensProvided, supplyInfo, borrowInfo);
    }

    function seizeTokens(
        address tonWallet,
        address targetUser,
        address tip3UserWallet,
        uint32 marketId,
        uint32 marketToLiquidate,
        uint256 tokensToSeize, 
        uint256 tokensToReturn,
        BorrowInfo borrowInfo
    ) external override view onlyModule(OperationCodes.LIQUIDATE_TOKENS) {
        address userAccount = _calculateUserAccountAddress(targetUser);
        IUserAccountData(userAccount).liquidateVTokens{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, tip3UserWallet, marketId, marketToLiquidate, tokensToSeize, tokensToReturn, borrowInfo);
    }

    function grantVTokens(
        address tonWallet, 
        address targetUser,
        address tip3UserWallet,
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 vTokensToGrant, 
        uint256 tokensToReturn
    ) external override view onlyValidUserAccountNoReserve(targetUser) {
        
        address targetAccount = _calculateUserAccountAddress(targetUser);
        IUserAccountData(targetAccount).checkUserAccountHealth{
            value: UserAccountCostConstants.updateHealthCost
        }(tonWallet);

        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).grantVTokens{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(targetUser, tip3UserWallet, marketId, marketToLiquidate, vTokensToGrant, tokensToReturn);
    }

    function abortLiquidation(
        address tonWallet,
        address targetUser,
        address tip3UserWallet, 
        uint32 marketId, 
        uint256 tokensToReturn
    ) external override view onlyModule(OperationCodes.LIQUIDATE_TOKENS) {
        address userAccount = _calculateUserAccountAddress(targetUser);
        IUserAccountData(userAccount).abortLiquidation{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, tip3UserWallet, marketId, tokensToReturn);
    }

    function returnAndSupply(
        address tonWallet,
        address tip3UserWallet,
        address userToUnlock,
        uint32 marketId,
        uint256 tokensToReturn
    ) external override view onlyValidUserAccountNoReserve(tonWallet) {
        if (tokensToReturn != 0) {
            uint128 tonsToUse = msg.value / 4;

            IMarketOperations(marketAddress).requestTokenPayout{
                value: tonsToUse * 3
            }(tonWallet, tip3UserWallet, marketId, tokensToReturn);
        }

        TvmBuilder tb;
        tb.store(tonWallet);
        ILockable(modules[OperationCodes.LIQUIDATE_TOKENS]).unlock{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(userToUnlock, tb.toCell());
    }

    /*********************************************************************************************************/
    // Account health calculation

    function requestUserAccountHealthCalculation(address tonWallet) external override view executor {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).checkUserAccountHealth{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet);
    }

    function calculateUserAccountHealth(
        address tonWallet, 
        address gasTo,
        mapping(uint32 => uint256) supplyInfo,
        mapping(uint32 => BorrowInfo) borrowInfo,
        TvmCell dataToTransfer
    ) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).calculateUserAccountHealth{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, gasTo, supplyInfo, borrowInfo, dataToTransfer);
    }

    function updateUserAccountHealth(
        address tonWallet, 
        address gasTo,
        fraction accountHealth, 
        mapping(uint32 => fraction) updatedIndexes,
        TvmCell dataToTransfer
    ) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).updateUserAccountHealth{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(gasTo, accountHealth, updatedIndexes, dataToTransfer);
    }

    /*********************************************************************************************************/
    // Requests from user account to market

    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external override view onlySelectedExecutors(OperationCodes.LIQUIDATE_TOKENS, tonWallet) {
        IMarketOperations(marketAddress).requestTokenPayout{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(tonWallet, userTip3Wallet, marketId, toPayout);
    }

    function withdrawExtraTons(address tonWallet) external onlyOwner {
        tvm.accept();
        address(tonWallet).transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED});
    }

    /*********************************************************************************************************/
    // Market managing functions

    /**
     * @param _market Address of market smart contract
     */
    function setMarketAddress(address _market) external override canChangeParams {
        tvm.accept();
        marketAddress = _market;
        address(_owner).transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED});
    }

    /*********************************************************************************************************/
    // Function for userAccountCode
    function uploadUserAccountCode(uint32 version, TvmCell code) external override canChangeParams {
        userAccountCodes[version] = code;
        
        address(msg.sender).transfer({flag: MsgFlag.ALL_NOT_RESERVED, value: 0});
    }

    function _updateUserAccount(address tonWallet) internal view {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        optional(uint32, TvmCell) latestVersion = userAccountCodes.max();
        if (latestVersion.hasValue()) {
            TvmCell empty;
            (uint32 codeVersion, TvmCell code) = latestVersion.get();
            IUpgradableContract(userAccount).upgradeContractCode{
                flag: MsgFlag.ALL_NOT_RESERVED
            }(code, empty, codeVersion);
        } else {
            address(userAccount).transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED});
        }
    }

    function updateUserAccount(address tonWallet) external override {
        _updateUserAccount(tonWallet);
    }

    function getUserAccountCode(uint32 version) external override view responsible returns(TvmCell) {
        return {flag: MsgFlag.ALL_NOT_RESERVED} userAccountCodes[version];
    }

    function disableUserAccountLock(address tonWallet) external view onlyOwner {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).disableBorrowLock{
            flag: MsgFlag.ALL_NOT_RESERVED
        }();
    }

    function removeMarket(address tonWallet, uint32 marketId) external view canChangeParams {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).removeMarket{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(marketId);
    }

    /*********************************************************************************************************/
    // Functions to add/remove modules info
    function addModule(uint8 operationId, address module) external override onlyTrusted {
        delete existingModules[module];
        modules[operationId] = module;
        existingModules[module] = true;
    }

    function removeModule(uint8 operationId) external override onlyTrusted {
        delete existingModules[modules[operationId]];
        delete modules[operationId];
    }

    /*********************************************************************************************************/
    // modifiers

    modifier onlyMarket() {
        require(
            msg.sender == marketAddress,
            UserAccountErrorCodes.ERROR_NOT_MARKET
        );
        _;
    }

    modifier onlyTrusted() {
        require(
            msg.sender == _owner ||
            msg.sender == marketAddress ||
            _canChangeParams[msg.sender],
            UserAccountErrorCodes.ERROR_NOT_TRUSTED
        );
        _;
    }

    modifier onlyModules() {
        require(
            existingModules.exists(msg.sender),
            UserAccountErrorCodes.ERROR_NOT_MODULE
        );
        _;
    }

    modifier executor() {
        require(
            msg.sender == _owner ||
            msg.sender == marketAddress ||
            existingModules.exists(msg.sender),
            UserAccountErrorCodes.ERROR_NOT_EXECUTOR
        );
        _;
    }

    modifier onlyModule(uint8 operationId) {
        require(
            msg.sender == modules[operationId],
            UserAccountErrorCodes.ERROR_INVALID_MODULE
        );
        _;
    }

    modifier onlySelectedExecutors(uint8 operationId, address tonWallet) {
        require(
            (msg.sender == modules[operationId]) ||
            (msg.sender == _calculateUserAccountAddress(tonWallet)),
            UserAccountErrorCodes.ERROR_INVALID_EXECUTOR
        );
        _;
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    modifier onlyValidUserAccount(address tonWallet) {
        require(
            msg.sender == _calculateUserAccountAddress(tonWallet),
            UserAccountErrorCodes.INVALID_USER_ACCOUNT
        );
        _;
    }

    modifier onlyValidUserAccountNoReserve(address tonWallet) {
        require(
            msg.sender == _calculateUserAccountAddress(tonWallet),
            UserAccountErrorCodes.INVALID_USER_ACCOUNT
        );
        _;
    }
}
