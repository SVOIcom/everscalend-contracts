pragma ton-solidity >= 0.47.0;

interface ITokenRoot {

    /*
        @notice Derive TokenWallet address from owner address
        @param _owner TokenWallet owner address
        @returns Token wallet address
    */
    function walletOf(address owner) external view responsible returns (address);

    /*
        @notice Deploy new TokenWallet
        @dev Can be called by anyone
        @param owner Token wallet owner address
        @param deployWalletValue Gas value to
    */
    function deployWallet(
        address owner,
        uint128 deployWalletValue
    ) external responsible returns (address);
}
