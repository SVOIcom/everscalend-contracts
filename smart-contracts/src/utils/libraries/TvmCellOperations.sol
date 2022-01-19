pragma ton-solidity >= 0.43.0;

library TvmCellOperations {
    function decodeOperation(TvmCell input) internal pure returns(uint8 operationId, TvmSlice data) {
        TvmSlice s = input.toSlice();
        operationId = s.decode(uint8);
        data = s.loadRefAsSlice();
    }

    function encodeOperation(uint8 operationId, TvmCell input) internal pure returns (TvmCell result) {
        TvmBuilder builder;
        builder.store(operationId);
        builder.store(input);
        result = builder.toCell();
    }
}