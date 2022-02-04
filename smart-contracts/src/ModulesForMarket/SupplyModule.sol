pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract SupplyModule is ACModule, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;

    event TokensSupplied(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokensSupplied);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
        actionId = OperationCodes.SUPPLY_TOKENS;
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
        actionId = OperationCodes.SUPPLY_TOKENS;
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function unlock(address, TvmCell) external override onlyOwner {}

    // Do not locking module, because exchange rate will be rebalanced automatically
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
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

        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, uint256 vTokensToProvide) = ts.decode(uint32, address, uint256);

        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, vTokensToProvide, marketInfo[marketId].index);
    }
}