pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;

contract Giver {
    constructor() public {
        tvm.accept();
    }

    function sendGrams(address dest, uint64 amount) external pure {
        tvm.accept();
        address(dest).transfer({value: amount, bounce: false});
    }
}