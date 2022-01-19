pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;

import "../libraries/MsgFlag.sol";

contract Platform {
    address static root;
    uint8 static platformType;
    TvmCell static initialData;
    TvmCell static platformCode;

    constructor(TvmCell contractCode, TvmCell params) public {
        tvm.accept();
        initializeContract(contractCode, params);
    }

    function initializeContract(TvmCell contractCode, TvmCell params) private {
        tvm.accept();
        TvmBuilder builder;

        builder.store(root);
        builder.store(platformType);

        builder.store(platformCode); // ref 1
        builder.store(initialData);  // ref 2
        builder.store(params);       // ref 3

        tvm.setcode(contractCode);
        tvm.setCurrentCode(contractCode);

        onCodeUpgrade(builder.toCell());
    }

    function onCodeUpgrade(TvmCell data) private {}
}