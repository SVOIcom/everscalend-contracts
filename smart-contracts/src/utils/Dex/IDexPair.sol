pragma ton-solidity >= 0.39.0;

struct IDexPairBalances {
    uint128 lp_supply;
    uint128 left_balance;
    uint128 right_balance;
}

interface IDexPair {
    function getBalances() external view responsible returns (IDexPairBalances);
}