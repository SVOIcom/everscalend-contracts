pragma ton-solidity >= 0.39.0;

library WalletControllerErrorCodes {
    uint8 constant ERROR_MSG_SENDER_IS_NOT_ROOT = 100;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_MARKET = 101;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_OWN_WALLET = 102;
    uint8 constant ERROR_TIP3_ROOT_IS_UNKNOWN = 103;

    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
}
