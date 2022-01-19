pragma ton-solidity >= 0.43.0;

struct MarketTokenAddresses {
    address realToken;
    address realTokenWallet;
}

interface IWalletControllerGetters {
    function getRealTokenRoots() external view responsible returns(mapping(address => bool));
    function getWallets() external view responsible returns(mapping(address => address));
    function getMarketAddresses(uint32 marketId) external view responsible returns(MarketTokenAddresses);
    function getAllMarkets() external view responsible returns(mapping(uint32 => MarketTokenAddresses));

    function createSupplyPayload() external pure returns(TvmCell);
    function createRepayPayload() external pure returns(TvmCell);
    function createLiquidationPayload(address targetUser, uint32 marketId) external pure returns(TvmCell);
}