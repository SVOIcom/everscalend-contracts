pragma ton-solidity >= 0.39.0;

import "../utils/libraries/FloatingPointOperations.sol";

struct DeltaInfo {
    bool positive;
    uint256 delta;
}

struct MarketInfo {
    address token;
    uint256 realTokenBalance;
    uint256 vTokenBalance;
    uint256 totalBorrowed;
    uint256 totalReserve;
    uint256 totalCash;

    fraction index;
    fraction baseRate;
    fraction utilizationMultiplier;
    fraction reserveFactor;
    fraction exchangeRate;
    fraction collateralFactor;
    fraction liquidationMultiplier;

    uint256 lastUpdateTime;
}

struct MarketDelta {
    DeltaInfo realTokenBalance;
    DeltaInfo vTokenBalance;
    DeltaInfo totalBorrowed;
    DeltaInfo totalReserve;
}
