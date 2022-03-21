pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';
import './libraries/ModuleCosts.sol';

import "../WalletController/libraries/CostConstants.sol";
import "../WalletController/libraries/WalletControllerErrorCodes.sol";

import '../utils/libraries/MsgFlag.sol';

import "../utils/TIP3.1/interfaces/IAcceptTokensTransferCallback.sol";

import "../utils/TIP3.1/interfaces/ITokenRoot.sol";
import "../utils/TIP3.1/interfaces/ITokenWallet.sol";
import "../utils/TIP3.1/interfaces/IManageTokenBalance.sol";

contract ConversionModule is ACModule, IConversionModule, IUpgradableContract, IAcceptTokensTransferCallback {
    using UFO for uint256;
    using FPO for fraction;

    mapping (uint32 => address) public _marketIdToTokenRoot;
    mapping (uint32 => address) public _marketToWallet;
    mapping (address => uint32) public _tokenRootToMarketId;
    mapping (address => address) public _tokenToWallet;
    mapping (address => bool) public _knownTokenRoots;
    mapping (address => bool) public _knownWallets;

    event TokenWithdraw(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 vTokensWithdrawn, uint256 realTokensWithdrawn);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
        actionId = OperationCodes.CONVERT_VTOKENS;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade (
            _owner,
            marketAddress,
            userAccountManager,
            marketInfo,
            tokenPrices,
            codeVersion
        );
    }

    function onCodeUpgrade(
        address owner,
        address _marketAddress,
        address _userAccountManager,
        mapping(uint32 => MarketInfo) _marketInfo,
        mapping(address => fraction) _tokenPrices,
        uint32 _codeVersion
    ) private {
        tvm.accept();
        tvm.resetStorage();
        actionId = OperationCodes.CONVERT_VTOKENS;
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {}

    function setMarketToken(uint32 marketId, address vTokenAddress) external onlyOwner {
        _marketIdToTokenRoot[marketId] = vTokenAddress;
        _tokenRootToMarketId[vTokenAddress] = marketId;
        _knownTokenRoots[vTokenAddress] = true;
        _deployWallet(vTokenAddress);
    }

    function _deployWallet(address _vTokenAddress) internal {
        ITokenRoot(_vTokenAddress).deployWallet{
            flag: MsgFlag.REMAINING_GAS,
            callback: this.receiveTIP3WalletAddress
        }(
            address(this),
            WCCostConstants.WALLET_DEPLOY_GRAMS
        );
    }

    function removeMarket(uint32 marketId) external canChangeParams {
        delete _knownWallets[_marketToWallet[marketId]];
        delete _tokenToWallet[_marketIdToTokenRoot[marketId]];
        delete _marketToWallet[marketId];
        delete _knownTokenRoots[_marketIdToTokenRoot[marketId]];
        delete _tokenRootToMarketId[_marketIdToTokenRoot[marketId]];
        delete _marketIdToTokenRoot[marketId];
    }

    /**
     * @param _wallet Receive deployed wallet address
     */
    function receiveTIP3WalletAddress(address _wallet) external onlyExisingTIP3Root(msg.sender) {
        tvm.accept();
        _marketToWallet[_tokenRootToMarketId[msg.sender]] = _wallet;
        _tokenToWallet[msg.sender] = _wallet;
        _knownWallets[_wallet] = true;
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address _user, uint256 _amount, uint32 _marketId) = ts.decode(address, uint256, uint32);
        if (!_isUserLocked(_user)) {
            _lockUser(_user, true);
            IUAMUserAccount(userAccountManager).requestConversionInfo{
                flag: MsgFlag.REMAINING_GAS
            }(_user, _amount, _marketId);
        } else {
            IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                flag: MsgFlag.REMAINING_GAS
            }(_user);
        }
    }

    function performConversion(
        address _user, 
        uint256 _amount, 
        uint32 marketId, 
        mapping (uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        MarketInfo mi = marketInfo[marketId];
        fraction accountHealth = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);

        fraction fTokensToSend = _amount.numFMul(mi.exchangeRate);
        fraction fTokensToSendUSD = fTokensToSend.fDiv(tokenPrices[marketInfo[marketId].token]);

        if (
            (accountHealth.nom > accountHealth.denom) &&
            (supplyInfo[marketId] >= _amount)
        ) {
            uint256 tokensToSend = fTokensToSend.toNum();
            if (
                accountHealth.nom - accountHealth.denom >= fTokensToSendUSD.toNum()
            ) {
                TvmCell empty;
                IMintTokens(_marketIdToTokenRoot[marketId]).mint{
                    value: ModuleCosts.mintTokens
                }(
                    uint128(_amount),
                    _user,
                    0,
                    _user,
                    true,
                    empty
                );
                IUAMUserAccount(userAccountManager).writeConversionInfo{
                    flag: MsgFlag.ALL_NOT_RESERVED
                }(_user, _amount, false, marketId);
            } else {
                IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                    flag: MsgFlag.REMAINING_GAS
                }(_user);
            }
        } else {
            IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                flag: MsgFlag.REMAINING_GAS
            }(_user);
        }
    }

    /*
        @notice Callback from TokenWallet on receive tokens transfer
        @param tokenWallet TokenWallet for which tokens were received
        @param tokenRoot TokenRoot of received tokens
        @param amount Received tokens amount
        @param sender Sender TokenWallet owner address
        @param senderWallet Sender TokenWallet address
        @param remainingGasTo Address specified for receive remaining gas
        @param payload Additional data attached to transfer by sender
    */
    function onAcceptTokensTransfer(
        address tokenRoot,
        uint128 amount,
        address sender,
        address senderWallet,
        address remainingGasTo,
        TvmCell payload
    ) external override onlyOwnWallet(tokenRoot, msg.sender)
    {
        TvmCell empty;
        IBurnTokens(tokenRoot).burnTokens{
            value: ModuleCosts.burnTokens
        }(
            amount,
            address(this),
            sender,
            address.makeAddrStd(0, 0),
            empty
        );

        IUAMUserAccount(userAccountManager).writeConversionInfo{
            flag: MsgFlag.ALL_NOT_RESERVED
        }(sender, amount, true, _tokenRootToMarketId[tokenRoot]);
    }

    function unlock(address addressToUnlock, TvmCell args) external override onlyUserAccountManager {
        _lockUser(addressToUnlock, false);
        address(addressToUnlock).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    modifier onlyOwnWallet(address _tokenRoot, address _sender) {
        require(
            _knownWallets[_sender],
            WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWN_WALLET
        );
        _;
    }

    modifier onlyExisingTIP3Root(address _tokenRoot) {
        require(
            _knownTokenRoots[_tokenRoot],
            WalletControllerErrorCodes.ERROR_TIP3_ROOT_IS_UNKNOWN
        );
        _;
    }
}