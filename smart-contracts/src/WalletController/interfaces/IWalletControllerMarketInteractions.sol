pragma ton-solidity >= 0.39.0;

interface IWCMInteractions {
    function transferTokensToWallet(address tonWallet, address tokenRoot, address userTip3Wallet, uint256 toPayout) external view;
}