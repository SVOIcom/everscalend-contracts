pragma ton-solidity >= 0.43.0;

import "../../utils/libraries/FloatingPointOperations.sol";

struct BorrowInfo {
    uint256 tokensBorrowed;
    fraction index;
}

struct UserMarketInfo {
    bool exists;
    uint32 _marketId;
    uint256 suppliedTokens;
    fraction accountHealth;
    BorrowInfo borrowInfo;
}

interface IUserAccount {
    function getOwner() external responsible view returns(address);

    function enterMarket(uint32 marketId) external;

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTip3Wallet) external;

    function withdrawExtraTons() external view;
}

interface IUserAccountData {
    // Supply operation
    function writeSupplyInfo(uint32 marketId_, uint256 tokensToSupply, fraction index) external;

    // Borrow operations
    function borrowUpdateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external;
    function writeBorrowInformation(uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external;

    // Repay operations
    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint256 tokensForRepay, mapping(uint32 => fraction) updatedIndexes) external;
    function writeRepayInformation(address userTip3Wallet, uint32 marketId_, uint256 tokensToReturn, BorrowInfo bi) external;

    // Withdraw operations
    function withdraw(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external view;
    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external;
    function requestWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external;

    // Liquidation operation
    function requestLiquidationInformation(address tonWallet, address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensProvided, mapping(uint32 => fraction) updatedIndexes) external;
    function liquidateVTokens(address tonWallet, address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn, BorrowInfo borrowInfo) external;
    function grantVTokens(address targetUser, address tip3UserWallet, uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn) external;
    function abortLiquidation(address tonWallet, address tip3UserWallet, uint32 marketId, uint256 tokensProvided) external;

    // Conversion operations
    function convertVTokens(uint256 amount, uint32 marketId) external view;
    function requestConversionInfo(uint256 _amount, uint32 _marketId) external view;
    function writeConversionInfo(uint256 _amount, bool positive, uint32 marketId) external;

    // Check user account health
    function checkUserAccountHealth(address gasTo) external;
    function updateUserAccountHealth(address gasTo, fraction _accountHealth, mapping(uint32 => fraction) updatedIndexes, TvmCell dataToTransfer) external;

    // Util operations
    function disableBorrowLock() external;
    function removeMarket(uint32 marketId) external;
}

interface IUserAccountGetters {
    function getKnownMarkets() external view responsible returns(mapping(uint32 => bool));
    function getMarketInfo(uint32 marketId) external view responsible returns(UserMarketInfo);
    function getAllMarketsInfo() external view responsible returns(mapping(uint32 => UserMarketInfo));
}