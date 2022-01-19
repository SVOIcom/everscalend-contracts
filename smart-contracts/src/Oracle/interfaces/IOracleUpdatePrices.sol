pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../utils/Dex/IDexPair.sol";

struct MarketPriceInfo {
    address swapPair;
    bool isLeft;
    uint128 tokens;
    uint128 usd;
}

interface IOracleUpdatePrices {
    function externalUpdatePrice(address tokenRoot, uint128 tokens, uint128 usd) external;
    function internalUpdatePrice(address tokenRoot) external;

    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) external;
}