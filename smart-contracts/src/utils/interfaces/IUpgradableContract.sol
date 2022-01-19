pragma ton-solidity >= 0.39.0;

interface IUpgradableContract {
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external;
}