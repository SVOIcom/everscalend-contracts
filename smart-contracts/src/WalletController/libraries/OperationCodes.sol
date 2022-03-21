pragma ton-solidity >= 0.39.0;

library OperationCodes {
    uint8 constant SUPPLY_TOKENS = 0;
    uint8 constant REPAY_TOKENS = 1;
    uint8 constant WITHDRAW_TOKENS = 2;
    uint8 constant BORROW_TOKENS = 3;
    uint8 constant LIQUIDATE_TOKENS = 4;
    uint8 constant CONVERT_VTOKENS = 5;
    uint8 constant REQUEST_TOKEN_PAYOUT = 100;
    uint8 constant RETURN_AND_UNLOCK = 200;
    uint8 constant RETURN_AND_UNLOCK_CONVERSION = 201;
    uint8 constant NO_OP = 255;
}