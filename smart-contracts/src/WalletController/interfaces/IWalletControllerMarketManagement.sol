pragma ton-solidity >= 0.39.0;

interface IWalletControllerMarketManagement {
    function setMarketAddress(address market) external;
    function addMarket(uint32 marketId, address realTokenRoot) external;
    function removeMarket(uint32 marketId) external;
}