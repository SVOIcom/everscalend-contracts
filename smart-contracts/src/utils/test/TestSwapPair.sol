pragma ton-solidity >= 0.39.0;

import '../Dex/IDexPair.sol';
import '../libraries/MsgFlag.sol';

contract TestSwapPair is IDexPair {
    uint256 static nonce;
    IDexPairBalances testBalance;

    constructor () public {
        tvm.accept();
    }

    function getBalances() override external responsible view returns (IDexPairBalances) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } testBalance;
    }

    function setBalances(uint128 left, uint128 right, uint128 minted) external {
        tvm.accept();
        testBalance = IDexPairBalances(minted, left, right);
    }
}