pragma ton-solidity >= 0.47.0;

import { ILockable, ACLockable } from './ILockable.sol';

import '../../Market/MarketInfo.sol';
import '../../Market/libraries/MarketOperations.sol';

import '../../UserAccount/interfaces/IUAMUserAccount.sol';

import '../../WalletController/libraries/OperationCodes.sol';

import '../../utils/interfaces/IUpgradableContract.sol';

import '../../utils/libraries/MsgFlag.sol';

import { IRoles } from '../../utils/interfaces/IRoles.sol';

interface IModule {
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
    function sendActionId() external view responsible returns(uint8);
    function getModuleState() external view returns (mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices);
}

interface IContractAddressSG {
    function setMarketAddress(address _marketAddress) external;
    function setUserAccountManager(address _userAccountManager) external;
    function getContractAddresses() external view responsible returns(address _owner, address _marketAddress, address _userAccountManager);
}

interface IContractStateCache {
    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
}

abstract contract ACModule is ACLockable, IModule, IContractAddressSG, IContractStateCache, IRoles {
    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;
    uint8 internal actionId;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    function sendActionId() external view override responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} actionId;
    }

    function getModuleState() 
        external 
        view 
        override 
        returns (
            mapping (uint32 => MarketInfo) _marketInfo, 
            mapping (address => fraction) _tokenPrices
        ) 
    {
        return (marketInfo, tokenPrices);
    }

    function setMarketAddress(address _marketAddress) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _marketAddress;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setUserAccountManager(address _userAccountManager) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(_owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function getContractAddresses() external override view responsible returns(address owner, address _marketAddress, address _userAccountManager) {
        return {flag: MsgFlag.REMAINING_GAS} (_owner, marketAddress, userAccountManager);
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function getGeneralLock() external returns(bool) {
        return _isLocked();
    }

    function userLock(address user) external returns(bool) {
        return _isUserLocked(user);
    }

    function usersLock() external returns(mapping(address => bool)) {
        return _userLocks;
    }

    function ownerGeneralUnlock(bool _locked) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        _generalLock(_locked);
        address(_owner).transfer({
            value: 0,
            flag: MsgFlag.REMAINING_GAS
        });
    }

    function ownerUserUnlock(address _user, bool _locked) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        _lockUser(_user, _locked);
        address(_owner).transfer({
            value: 0,
            flag: MsgFlag.REMAINING_GAS
        });
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}

interface IContractStateCacheRoot {
    function receiveCacheDelta(mapping(uint32 => MarketDelta) marketsDelta, TvmCell args) external;
}

interface ISupplyModule {

}

interface IWithdrawModule {
    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external;
}

interface IBorrowModule {
    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external;
}

interface IRepayModule {
    function repayLoan(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external;
}

interface ILiquidationModule {
    function liquidate(
        address tonWallet, 
        address targetUser, 
        address tip3UserWallet, 
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 tokensProvided, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external;
}

library Utilities {
    using UFO for uint256;
    using FPO for fraction;

    function calculateSupplyBorrow(
        mapping(uint32 => uint256) supplyInfo,
        mapping(uint32 => BorrowInfo) borrowInfo,
        mapping(uint32 => MarketInfo) marketInfo,
        mapping(address => fraction) tokenPrices
    ) internal returns (fraction) {
        fraction accountHealth = fraction(0, 0);
        fraction tmp;
        fraction nom = fraction(0, 1);
        fraction denom = fraction(0, 1);

        // Supply:
        // 1. Calculate real token amount: vToken*exchangeRate
        // 2. Calculate real token amount in USD: realTokens/tokenPrice
        // 3. Multiply by collateral factor: usdValue*collateralFactor
        for ((uint32 marketId, uint256 supplied): supplyInfo) {
            tmp = supplied.numFMul(marketInfo[marketId].exchangeRate);
            tmp = tmp.fDiv(tokenPrices[marketInfo[marketId].token]);
            tmp = tmp.fMul(marketInfo[marketId].collateralFactor);
            nom = nom.fAdd(tmp);
            nom = nom.simplify();
        }

        // Borrow:
        // 1. Recalculate borrow amount according to new index
        // 2. Calculate borrow value in USD
        // NOTE: no conversion from vToken to real tokens required, as value is stored in real tokens
        for ((uint32 marketId, BorrowInfo _bi): borrowInfo) {
            if (_bi.tokensBorrowed != 0) {
                if (!_bi.index.eq(marketInfo[marketId].index)) {
                    tmp = borrowInfo[marketId].tokensBorrowed.numFMul(marketInfo[marketId].index);
                    tmp = tmp.fDiv(borrowInfo[marketId].index);
                } else {
                    tmp = borrowInfo[marketId].tokensBorrowed.toF();
                }
                tmp = tmp.fDiv(tokenPrices[marketInfo[marketId].token]);
                tmp = tmp.simplify();
                denom = denom.fAdd(tmp);
                denom = denom.simplify();
            }
        }

        accountHealth = nom.fDiv(denom);

        return accountHealth;
    }
}