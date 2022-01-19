pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./libraries/UserAccountErrorCodes.sol";

import "./interfaces/IUAMUserAccount.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

import '../WalletController/libraries/OperationCodes.sol';

contract UserAccount is IUserAccount, IUserAccountData, IUpgradableContract, IUserAccountGetters {
    using UFO for uint256;
    using FPO for fraction;

    bool public borrowLock;
    bool public liquidationLock;

    address static public owner;
    
    // Used for interactions with market 
    address public userAccountManager;

    // Information for update
    uint32 public contractCodeVersion;

    fraction public accountHealth;

    mapping(uint32 => bool) knownMarkets;
    mapping(uint32 => UserMarketInfo) markets;

    function getKnownMarkets() external override view responsible returns(mapping(uint32 => bool)) {
        return {flag: MsgFlag.REMAINING_GAS} knownMarkets;
    }

    function getAllMarketsInfo() external override view responsible returns(mapping(uint32 => UserMarketInfo)) {
        return {flag: MsgFlag.REMAINING_GAS} markets;
    }

    function getMarketInfo(uint32 marketId) external override view responsible returns(UserMarketInfo) {
        return {flag: MsgFlag.REMAINING_GAS} markets[marketId];
    }

    // Contract is deployed via platform
    constructor() public { 
        tvm.accept();
        userAccountManager = msg.sender;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyUserAccountManager {
        require(!borrowLock);
        tvm.accept();

        bool _borrowLock = borrowLock;
        bool _liquidationLock = liquidationLock;
        address _owner = owner;
        address _userAccountManager = userAccountManager;
        mapping (uint32 => bool) _knownMarkets = knownMarkets;
        mapping (uint32 => UserMarketInfo) _markets = markets;
        fraction _accountHealth = accountHealth;

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            _borrowLock,
            _liquidationLock,
            _owner,
            _userAccountManager,
            _knownMarkets,
            _markets,
            _accountHealth,
            updateParams,
            codeVersion
        );
    }

    function onCodeUpgrade(
        bool _borrowLock,
        bool _liquidationLock,
        address _owner,
        address _userAccountManager,
        mapping(uint32 => bool) _knownMarkets,
        mapping(uint32 => UserMarketInfo) _markets,
        fraction _accountHealth,
        TvmCell,
        uint32 codeVersion
    ) private {
        tvm.resetStorage();
        borrowLock = _borrowLock;
        liquidationLock = _liquidationLock;
        owner = _owner;
        userAccountManager = _userAccountManager;
        knownMarkets = _knownMarkets;
        markets = _markets;
        accountHealth = _accountHealth;

        contractCodeVersion = codeVersion;
    }

    function getOwner() external override responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } owner;
    }

    /*********************************************************************************************************/
    // Supply functions

    function writeSupplyInfo(uint32 marketId, uint256 tokensToSupply, fraction index) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        markets[marketId].suppliedTokens += tokensToSupply;
        _updateMarketInfo(marketId, index);

        _checkUserAccountHealth(owner, _createNoOpPayload());
    }

    /*********************************************************************************************************/
    // Withdraw functions

    function withdraw(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external override view onlyOwner {
        if (
            !liquidationLock &&
            tokensToWithdraw <= markets[marketId].suppliedTokens
        ) {
            tvm.rawReserve(msg.value, 2);
            
            IUAMUserAccount(userAccountManager).requestWithdraw{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId, tokensToWithdraw);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function requestWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        if (
            accountHealth.nom > accountHealth.denom
        ) {
            for ((uint32 marketId_, fraction index): updatedIndexes) {
                _updateMarketInfo(marketId_, index);
            }

            mapping(uint32 => BorrowInfo) borrowInfo;
            mapping(uint32 => uint256) supplyInfo;

            (borrowInfo, supplyInfo) = _getBorrowSupplyInfo();

            IUAMUserAccount(userAccountManager).receiveWithdrawInfo{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, tokensToWithdraw, marketId, supplyInfo, borrowInfo);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external override onlyUserAccountManager{
        tvm.rawReserve(msg.value, 2);
        markets[marketId].suppliedTokens -= tokensToWithdraw;
        _checkUserAccountHealth(owner, _createTokenPayoutPayload(owner, userTip3Wallet, marketId, tokensToSend));
    }

    /*********************************************************************************************************/
    // Borrow functions

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTip3Wallet) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (
            (!borrowLock) &&
            (accountHealth.nom > accountHealth.denom) &&
            !liquidationLock
        ) {
            borrowLock = true;
            TvmBuilder tb;
            tb.store(owner);
            tb.store(userTip3Wallet);
            tb.store(amountToBorrow);
            IUAMUserAccount(userAccountManager).requestIndexUpdate{
                flag: MsgFlag.REMAINING_GAS
            }(owner, marketId, tb.toCell());
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function borrowUpdateIndexes(uint32 marketId, mapping(uint32 => fraction) updatedIndexes, address userTip3Wallet, uint256 toBorrow) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        _updateIndexes(updatedIndexes);

        mapping(uint32 => BorrowInfo) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;

        (borrowInfo, supplyInfo) = _getBorrowSupplyInfo();

        IUAMUserAccount(userAccountManager).passBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, toBorrow, supplyInfo, borrowInfo);
    }

    function writeBorrowInformation(uint32 marketId, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        if (toBorrow > 0) {
            _updateMarketInfo(marketId, marketIndex);
            markets[marketId].borrowInfo.tokensBorrowed += toBorrow;
        }

        borrowLock = false;

        if (toBorrow > 0) {
            _checkUserAccountHealth(owner, _createTokenPayoutPayload(owner, userTip3Wallet, marketId, toBorrow));
        } else {
            _checkUserAccountHealth(owner, _createNoOpPayload());
        }
    }

    /*********************************************************************************************************/
    // repay functions

    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint256 tokensForRepay, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }

        IUAMUserAccount(userAccountManager).receiveRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, tokensForRepay, marketId, markets[marketId].borrowInfo);
    }

    function writeRepayInformation(address userTip3Wallet, uint32 marketId, uint256 tokensToReturn, BorrowInfo bi) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        markets[marketId].borrowInfo = bi;
        
        if (tokensToReturn != 0) { 
            _checkUserAccountHealth(owner, _createTokenPayoutPayload(owner, userTip3Wallet, marketId, tokensToReturn));
        } else {
            _checkUserAccountHealth(owner, _createNoOpPayload());
        }
    }

    /*********************************************************************************************************/
    // Check account health functions

    function checkUserAccountHealth(address gasTo) external override onlyExecutor {
        tvm.rawReserve(msg.value, 2);
        TvmBuilder no_op;
        no_op.store(OperationCodes.NO_OP);

        _checkUserAccountHealth(gasTo, no_op.toCell());
    }

    function _checkUserAccountHealth(address gasTo, TvmCell dataToTransfer) internal view {
        mapping(uint32 => uint256) supplyInfo;
        mapping(uint32 => BorrowInfo) borrowInfo;
        (borrowInfo, supplyInfo) = _getBorrowSupplyInfo();
        IUAMUserAccount(userAccountManager).calculateUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }(owner, gasTo, supplyInfo, borrowInfo, dataToTransfer);
    }

    function updateUserAccountHealth(address gasTo, fraction _accountHealth, mapping(uint32 => fraction) updatedIndexes, TvmCell dataToTransfer) external override onlyUserAccountManager {
        accountHealth = _accountHealth;
        liquidationLock = accountHealth.denom > accountHealth.nom;
        borrowLock = accountHealth.denom > accountHealth.nom;
        _updateIndexes(updatedIndexes);
        TvmSlice ts = dataToTransfer.toSlice();
        (uint8 operation) = ts.decode(uint8);
        if (operation == OperationCodes.REQUEST_TOKEN_PAYOUT) {
            (address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToPayout) = ts.decode(address, address, uint32, uint256);
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, userTip3Wallet, marketId, tokensToPayout);
        } else {
            address(gasTo).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function removeMarket(uint32 marketId) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        delete markets[marketId];
        delete knownMarkets[marketId];
        address(userAccountManager).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Liquidation functions

    function requestLiquidationInformation(address tonWallet, address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensProvided, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        _updateIndexes(updatedIndexes);

        (mapping(uint32 => BorrowInfo) borrowInfo, mapping(uint32 => uint256) supplyInfo) = _getBorrowSupplyInfo();

        IUAMUserAccount(userAccountManager).receiveLiquidationInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, owner, tip3UserWallet, marketId, marketToLiquidate, tokensProvided, supplyInfo, borrowInfo);
    }

    function liquidateVTokens(address tonWallet, address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn, uint256 tokensFromReserve, BorrowInfo borrowInfo) external override onlyUserAccountManager {
        markets[marketToLiquidate].suppliedTokens -= tokensToSeize;
        markets[marketId].borrowInfo = borrowInfo;

        IUAMUserAccount(userAccountManager).grantVTokens{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, owner, tip3UserWallet, marketId, marketToLiquidate, tokensToSeize, tokensToReturn, tokensFromReserve);
    }

    function grantVTokens(address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn, uint256 tokensFromReserve) external override onlyUserAccountManager {
        markets[marketToLiquidate].suppliedTokens += tokensToSeize;
        if (tokensFromReserve != 0) {
            IUAMUserAccount(userAccountManager).returnAndSupply{
                flag: MsgFlag.REMAINING_GAS
            }(owner, tip3UserWallet, marketId, marketToLiquidate, tokensToReturn, tokensFromReserve);
        } else {
            if (tokensToReturn != 0) {
                _checkUserAccountHealth(owner, _createTokenPayoutPayload(owner, tip3UserWallet, marketId, tokensToReturn));
            } else {
                _checkUserAccountHealth(owner, _createNoOpPayload());
            }
        }
    }

    function abortLiquidation(address tonWallet, address tip3UserWallet, uint32 marketId, uint256 tokensProvided) external override onlyUserAccountManager {
        if (tokensProvided != 0) { 
            _checkUserAccountHealth(owner, _createTokenPayoutPayload(tonWallet, tip3UserWallet, marketId, tokensProvided));
        } else {
            _checkUserAccountHealth(owner, _createNoOpPayload());
        }
    }

    /*********************************************************************************************************/
    // internal functions
    
    function _updateIndexes(mapping(uint32 => fraction) updatedIndexes) internal {
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }
    }

    function _updateMarketInfo(uint32 marketId, fraction index) internal {
        fraction tmpf;
        BorrowInfo bi = markets[marketId].borrowInfo;
        if (markets[marketId].borrowInfo.tokensBorrowed != 0) {
            tmpf = bi.tokensBorrowed.numFMul(index);
            tmpf = tmpf.fDiv(bi.index);
        } else {
            tmpf = fraction(0, 1);
        }
        markets[marketId].borrowInfo = BorrowInfo(tmpf.toNum(), index);
    }

    function _getBorrowSupplyInfo() internal view returns(mapping(uint32 => BorrowInfo) borrowInfo, mapping(uint32 => uint256) supplyInfo) {
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.suppliedTokens;
            borrowInfo[marketId] = umi.borrowInfo;
        }
    }

    function _createTokenPayoutPayload(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToSend) internal pure returns (TvmCell) {
        TvmBuilder op;
        op.store(OperationCodes.REQUEST_TOKEN_PAYOUT);
        op.store(tonWallet);
        op.store(userTip3Wallet);
        op.store(marketId);
        op.store(tokensToSend);
        return op.toCell();
    }

    function _createNoOpPayload() internal pure returns (TvmCell) {
        TvmBuilder no_op;
        no_op.store(OperationCodes.NO_OP);
        return no_op.toCell();
    }

    function disableBorrowLock() external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        borrowLock = false;
        address(userAccountManager).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/

    // Functon can only be called by the AccountManaget contract
    /**
     * @param marketId Id of market to enter
     */
    function enterMarket(uint32 marketId) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!knownMarkets[marketId]) {
            knownMarkets[marketId] = true;

            markets[marketId].exists = true;
            markets[marketId]._marketId = marketId;
            markets[marketId].suppliedTokens = 0;
        }
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Functions for owner

    function withdrawExtraTons() external override view onlyOwner {
        address(owner).transfer({ value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED });
    }

    /*********************************************************************************************************/
    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyExecutor() {
        require(
            msg.sender == userAccountManager ||
            msg.sender == owner ||
            msg.sender == address(this)
        );
        _;
    }
}