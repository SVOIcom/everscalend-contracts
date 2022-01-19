pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleManageTokens {
    function addToken(address tokenRoot, address swapPairAddress, bool isLeft) external;
    function removeToken(address tokenRoot) external;
}