pragma ton-solidity >= 0.39.0;

interface ITIP3DeployerServiceInfo {
    struct ServiceInfo {
        TvmCell rootCode;
        TvmCell walletCode;
    }

    function getServiceInfo() external responsible view returns(ServiceInfo);
}