pragma ton-solidity >= 0.39.0;

library UserAccountErrorCodes {
    uint8 constant ERROR_NOT_ROOT = 102;

    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
    
    uint8 constant ERROR_NOT_APPROVED_MARKET = 104; 
    uint8 constant ERROR_NOT_ENTERED_MARKET = 105;

    uint8 constant ERROR_NOT_MARKET = 106;
    uint8 constant ERROR_NOT_TRUSTED = 107;
    uint8 constant ERROR_NOT_MODULE = 108;
    uint8 constant ERROR_NOT_EXECUTOR = 109;
    uint8 constant ERROR_INVALID_MODULE = 110;
    uint8 constant ERROR_INVALID_EXECUTOR = 111;
    uint8 constant INVALID_USER_ACCOUNT = 112;
    
}