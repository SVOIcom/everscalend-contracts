pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract SupplyModule is IRoles, IModule, IContractStateCache, IContractAddressSG, IUpgradableContract {

    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event TokensSupplied(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokensSupplied);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external override canUpgrade {
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
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.SUPPLY_TOKENS;
    }

    function getModuleState() external override view returns(mapping(uint32 => MarketInfo), mapping(address => fraction)) {
        return(marketInfo, tokenPrices);
    }

    function setMarketAddress(address _marketAddress) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _marketAddress;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setUserAccountManager(address _userAccountManager) external override canChangeParams {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function getContractAddresses() external override view responsible returns(address _owner, address _marketAddress, address _userAccountManager) {
        return {flag: MsgFlag.REMAINING_GAS} (_owner, marketAddress, userAccountManager);
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, uint256 tokenAmount) = ts.decode(address, uint256);

        // Supply process:
        // 1. Convert real tokens to vTokens by dividing real token amount by exchange rate
        fraction vTokensToProvide = tokenAmount.numFDiv(marketInfo[marketId].exchangeRate);

        MarketDelta marketDelta;
        mapping(uint32 => MarketDelta) marketsDelta;
        marketDelta.realTokenBalance.delta = tokenAmount;
        marketDelta.realTokenBalance.positive = true;
        marketDelta.vTokenBalance.delta = vTokensToProvide.toNum();
        marketDelta.vTokenBalance.positive = true;
        marketsDelta[marketId] = marketDelta;

        TvmBuilder tb;
        tb.store(marketId);
        tb.store(tonWallet);
        tb.store(vTokensToProvide.toNum());

        emit TokensSupplied(marketId, marketDelta, tonWallet, tokenAmount);

        IContractStateCacheRoot(marketAddress).receiveCacheDelta{
            flag: MsgFlag.REMAINING_GAS
        }(marketsDelta, tb.toCell());
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;

        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, uint256 vTokensToProvide) = ts.decode(uint32, address, uint256);

        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, vTokensToProvide, marketInfo[marketId].index);
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}