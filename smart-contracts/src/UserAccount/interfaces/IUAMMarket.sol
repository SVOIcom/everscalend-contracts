pragma ton-solidity >= 0.39.0;

interface IUAMMarket {
    function setMarketAddress(address _market) external;
    function addModule(uint8 operationId, address module) external;
    function removeModule(uint8 operationId) external;
}