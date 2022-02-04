pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract BorrowModule is ACModule, IBorrowModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    event TokenBorrow(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokensBorrowed);

    constructor(address _newOwner) public {
        tvm.accept();
        _owner = _newOwner;
        actionId = OperationCodes.BORROW_TOKENS;
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
        actionId = OperationCodes.BORROW_TOKENS;
        _owner = owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function unlock(address, TvmCell) external override onlyOwner {}

    // This module will lock itself in order not to mess with market parameters and to prevent some attacks
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(address, address, uint256);
        if (!_isLocked()) {
            _generalLock(true);

            mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
            IUAMUserAccount(userAccountManager).updateUserIndexes{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, updatedIndexes);
        } else {
            IUAMUserAccount(userAccountManager).writeBorrowInformation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, userTip3Wallet, 0, marketId, _marketInfo[marketId].index);
        }
    }

    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        mapping(uint32 => MarketDelta) marketsDelta;
        MarketDelta marketDelta;
        
        // Borrow:
        // 1. Check that market has enough tokens for lending
        // 2. Calculate user account health
        // 3. Calculate USD value of tokens to borrow
        // 4. Check if there is enough (collateral - borrowed) for new token borrow
        // 5. Increase user's borrowed amount

        MarketInfo mi = marketInfo[marketId];

        if (tokensToBorrow < mi.totalCash) {
            fraction accountHealth = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);
            if (accountHealth.nom > accountHealth.denom) {
                uint256 healthDelta = accountHealth.nom - accountHealth.denom;
                fraction tmp = healthDelta.numFMul(tokenPrices[mi.token]);
                uint256 possibleTokenWithdraw = tmp.toNum();
                if (possibleTokenWithdraw >= tokensToBorrow) {
                    marketDelta.totalBorrowed.delta = tokensToBorrow;
                    marketDelta.totalBorrowed.positive = true;
                    marketDelta.realTokenBalance.delta = tokensToBorrow;
                    marketDelta.realTokenBalance.positive = false;

                    marketsDelta[marketId] = marketDelta;

                    TvmBuilder tb;
                    tb.store(marketId);
                    tb.store(tonWallet);
                    tb.store(userTip3Wallet);
                    tb.store(tokensToBorrow);

                    emit TokenBorrow(marketId, marketDelta, tonWallet, tokensToBorrow);

                    IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                        flag: MsgFlag.REMAINING_GAS
                    }(marketsDelta, tb.toCell());
                } else {
                    _generalLock(false);
                    IUAMUserAccount(userAccountManager).writeBorrowInformation{
                        flag: MsgFlag.REMAINING_GAS
                    }(tonWallet, userTip3Wallet, 0, marketId, mi.index);
                }
            } else {
                _generalLock(false);
                IUAMUserAccount(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, 0, marketId, mi.index);
            }
        } else {
            _generalLock(false);
            IUAMUserAccount(userAccountManager).writeBorrowInformation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, userTip3Wallet, 0, marketId, mi.index);
        }
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        // Unlock module
        _generalLock(false);
        TvmSlice ts = args.toSlice();
        (uint32 marketId, address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(uint32, address, address, uint256);
        IUAMUserAccount(userAccountManager).writeBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, _marketInfo[marketId].index);
    }
}