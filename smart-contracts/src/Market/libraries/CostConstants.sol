pragma ton-solidity >= 0.39.0;

library CostConstants {
    uint128 constant FETCH_TIP3_ROOT_INFORMATION = 0.2 ton;
    uint128 constant SEND_TO_TIP3_DEPLOYER = 1.5 ton;
    uint128 constant USE_TO_DEPLOY_TIP3_ROOT = 1 ton;
    uint128 constant NOTIFY_CONTRACT_CONTROLLER = 0.2 ton;
}