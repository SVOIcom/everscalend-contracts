pragma ton-solidity >= 0.39.0;

library OracleErrorCodes {
    uint8 constant ERROR_NOT_OWNER = 100;
    uint8 constant ERROR_NOT_TRUSTED = 101;
    uint8 constant ERROR_NOT_ROOT = 102;

    uint8 constant ERROR_NOT_KNOWN_SWAP_PAIR = 110;
    uint8 constant ERROR_NOT_KNOWN_TOKEN_ROOT = 111;

    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
}