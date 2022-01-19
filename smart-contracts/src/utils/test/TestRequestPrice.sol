pragma ton-solidity >= 0.39.0;

import '../../Oracle/interfaces/IOracleReturnPrices.sol';

contract TestRequestPrice {
    address oracle;
    uint128 tokens;
    uint128 usd;
    TvmCell payloadToSend;
    TvmCell receivedPayload;

    constructor() public {
        tvm.accept();
    }

    function requestPrice(address tokenRoot) external {
        tvm.accept();
        IOracleReturnPrices(oracle).getTokenPrice{
            value: 0.2 ton,
            bounce: false,
            flag: 1,
            callback: this.receivePriceCallback
        }(tokenRoot, payloadToSend);
    }

    function setInitialInfo(address _oracle, TvmCell payload) external {
        tvm.accept();
        oracle = _oracle;
        payloadToSend = payload;
    }

    function resetPrice() external {
        tvm.accept();
        usd = 0;
        tokens = 0;
    }

    function receivePriceCallback(uint128 tokens_, uint128 usd_, TvmCell payload) external {
        tvm.accept();
        tokens = tokens_;
        usd = usd_;
        receivedPayload = payload;
    }

    function getResults() external responsible returns(uint128, uint128, TvmCell) {
        return (tokens, usd, receivedPayload);
    }
}