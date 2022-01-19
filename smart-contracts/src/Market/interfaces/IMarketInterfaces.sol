pragma ton-solidity >= 0.43.0;

import '../MarketInfo.sol';

import "../libraries/CostConstants.sol";
import "../libraries/MarketErrorCodes.sol";
import "../libraries/MarketOperations.sol";

import "../../WalletController/interfaces/IWalletControllerMarketInteractions.sol";
import '../../WalletController/interfaces/IWalletControllerMarketManagement.sol';
import "../../UserAccount/interfaces/IUserAccount.sol";
import "../../UserAccount/interfaces/IUAMUserAccount.sol";
import "../../Oracle/interfaces/IOracleReturnPrices.sol";

import "../../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../../utils/interfaces/IUpgradableContract.sol";
import "../../utils/libraries/MsgFlag.sol";
import "../../utils/libraries/FloatingPointOperations.sol";

interface IMarketOracle {
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell payload) external;
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external;
}

interface IMarketSetters {
    function setUserAccountManager(address _userAccountManager) external;
    function setWalletController(address _tip3WalletController) external;
    function setOracleAddress(address _oracle) external;
}

interface IMarketGetters {
    function getServiceContractAddresses() external view responsible returns(address _userAccountManager, address _tip3WalletController, address _oracle);
    function getTokenPrices() external view responsible returns(mapping(address => fraction));
    function getMarketInformation(uint32 marketId) external view responsible returns(MarketInfo);
    function getAllMarkets() external view responsible returns(mapping(uint32 => MarketInfo));
    function getAllModules() external view responsible returns(mapping(uint8 => address));
}

interface IMarketOwnerFunctions {
    function withdrawExtraTons(uint128 amount) external;
    function updateModulesCache() external view;
    function forceUpdateAllPrices() external; 
}

interface IMarketOperations {
    function performOperationWalletController(uint8 operationId, address tokenRoot, TvmCell args) external view;
    function performOperationUserAccountManager(uint8 operationId, uint32 marketId, TvmCell args) external view;
    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external view;
    function calculateUserAccountHealth(address tonWallet, address gasTo, mapping(uint32 => uint256) supplyInfo, mapping(uint32 => BorrowInfo) borrowInfo, TvmCell payload) external;
}
