pragma ton-solidity >= 0.39.0;

interface ITIP3DeployerManageCode {
    function setTIP3RootContractCode(TvmCell _rootContractCode) external;

    function setTIP3WalletContractCode(TvmCell _walletContractCode) external;
}