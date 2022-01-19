pragma ton-solidity >= 0.43.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./IOracleUpdatePrices.sol";

interface IOracleReturnPrices {
    function getTokenPrice(address tokenRoot, TvmCell payload) external responsible view returns (address, uint128, uint128, TvmCell);
    function getAllTokenPrices(TvmCell payload) external responsible view returns (mapping(address => MarketPriceInfo), TvmCell);
}