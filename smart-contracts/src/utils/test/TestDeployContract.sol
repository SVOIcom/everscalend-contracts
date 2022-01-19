pragma ton-solidity >= 0.39.0;

contract TestDeployContract {
    constructor() public {
        revert();
    }

    function onCodeUpgrade(TvmCell upgradeData) private {
        tvm.resetStorage();
    }

    function iExist() external responsible returns(bool) {
        return true;
    }
}