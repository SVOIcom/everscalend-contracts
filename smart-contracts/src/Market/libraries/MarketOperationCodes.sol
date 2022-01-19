pragma ton-solidity >= 0.43.0;

library MarketOperationCodes {
    uint8 constant SUPPLY_TOKENS = 0;
    uint8 constant WITHDRAW_TOKENS = 1;
    uint8 constant BORROW_TOKENS = 2;
    uint8 constant REPAY_LOAN = 3;
    uint8 constant LIQUIDATE_LOAN = 4;

    uint8 constant RESUME_SUPPLY_TOKENS = 10;
    uint8 constant RESUME_WITHDRAW_TOKENS = 11;
    uint8 constant RESUME_BORROW_TOKENS = 12;
    uint8 constant RESUME_REPAY_LOAN = 13;
    uint8 constant RESUME_LIQUIDATE_LOAN = 14;

    uint8 constant WRITE_SUPPLY_TOKENS = 20;
    uint8 constant WRITE_WITHDRAW_TOKENS = 21;
    uint8 constant WRITE_BORROW_TOKENS = 22;
    uint8 constant WRITE_REPAY_LOAN = 23;
    uint8 constant WRITE_LIQUIDATE_LOAN = 24;

    uint8 constant RESPONSE_SUPPLY_TOKENS = 30;
    uint8 constant RESPONSE_WITHDRAW_TOKENS = 31;
    uint8 constant RESPONSE_BORROW_TOKENS = 32;
    uint8 constant RESPONSE_REPAY_LOAN = 33;
    uint8 constant RESPONSE_LIQUIDATE_LOAN = 34;

    uint8 constant BORROW_FINALIZE = 40;

    uint8 constant REQUEST_INDEX_UPDATE = 50;

    uint8 constant INDEX_UPDATE_RESPONSE = 60;


}