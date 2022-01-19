pragma ton-solidity >= 0.39.0;

library TIP3DeployerErrorCodes {
    uint8 constant ERROR_MSG_SENDER_IS_NOT_OWNER = 100;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_ROOT = 101;

    uint8 constant ERROR_MSG_VALUE_IS_TOO_LOW = 110;

    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
}