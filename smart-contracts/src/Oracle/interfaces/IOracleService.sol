pragma ton-solidity >= 0.43.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleService {
    struct OracleServiceInformation {
        uint32 codeVersion;
        address ownerAddress;
    }
    
    function getVersion() external responsible view returns (uint32);
    function getDetails() external responsible view returns (OracleServiceInformation);
}