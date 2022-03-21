pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IBurnTokens {
    /*
        @notice Burn tokens at specific token wallet
        @dev Can be called only by owner address
        @dev Don't support token wallet owner public key
        @param amount How much tokens to burn
        @param owner Token wallet owner address
        @param send_gas_to Receiver of the remaining balance after burn. sender_address by default
        @param callback_address Burn callback address
        @param callback_payload Burn callback payload
    */
    function burnTokens(
        uint128 amount,
        address walletOwner,
        address remainingGasTo,
        address callbackTo,
        TvmCell payload
    ) external;
}

interface IMintTokens {
        /*
        @notice Mint tokens to recipient with deploy wallet optional
        @dev Can be called only by owner
        @param amount How much tokens to mint
        @param recipient Minted tokens owner address
        @param deployWalletValue How much EVERs send to wallet on deployment, when == 0 then not deploy wallet before mint
        @param remainingGasTo Receiver the remaining balance after deployment. root owner by default
        @param notify - when TRUE and recipient specified 'callback' on his own TokenWallet,
                        then send IAcceptTokensTransferCallback.onAcceptTokensMint to specified callback address,
                        else this param will be ignored
        @param payload - custom payload for IAcceptTokensTransferCallback.onAcceptTokensMint
    */
    function mint(
        uint128 amount,
        address recipient,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) external;
}