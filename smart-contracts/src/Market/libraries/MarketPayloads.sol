pragma ton-solidity >= 0.39.0;

import "./MarketOperationCodes.sol";
import "../../utils/libraries/FloatingPointOperations.sol";

library MarketToUserPayloads {


    function createSupplyPayload(uint32 marketId, uint256 providedTokens, uint128 realTokens, address userTIP3Wallet) internal pure returns (TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.SUPPLY_TOKENS);
        TvmBuilder op;
        op.store(marketId);
        op.store(providedTokens);
        op.store(realTokens);
        op.store(userTIP3Wallet);
        tb.store(op.toCell());
        return tb.toCell();
    }

    function decodeSupplyOperation(TvmCell args) internal pure returns(uint32, uint256, uint128, address) {
        TvmSlice ts = args.toSlice();
        return ts.decode(uint32, uint256, uint128, address);
    }

    function createBorrowPayload(uint32 marketId, uint256 tokensToBorrow, address userTargetWallet) internal pure returns (TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.BORROW_TOKENS);
        TvmBuilder op;
        op.store(marketId);
        op.store(tokensToBorrow);
        op.store(userTargetWallet);
        tb.storeRef(op.toCell());
        return tb.toCell();
    }

    function createRepayPayload(uint32 marketId, uint256 tokensToRepay) internal pure returns (TvmCell) {

    }

    function getOperationType(TvmCell payload) internal pure returns (uint8, TvmCell) {
        TvmSlice ts = payload.toSlice();
        uint8 op = ts.decode(uint8);
        TvmCell opArgs = ts.loadRef();
        return (op, opArgs);
    }

    function decodeBorrowOperation(TvmCell args) internal pure returns(uint32, uint256, address) {
        TvmSlice ts = args.toSlice();
        return ts.decode(uint32, uint256, address);
    }

    function encodeBorrow(address tonWallet, address userTip3Wallet, uint256 toBorrow, mapping(uint32 => uint256) bi, mapping(uint32 => uint256) si) internal pure returns (TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.BORROW_TOKENS);
        TvmBuilder op;
        op.store(tonWallet);
        op.store(userTip3Wallet);
        op.store(toBorrow);
        op.store(bi);
        op.store(si);
        tb.store(op.toCell());
        return tb.toCell();
    }

    function decodeBorrow(TvmCell args) internal pure returns (address, uint32, address, uint256, mapping(uint32 => uint256), mapping(uint32 => uint256)) {
        TvmSlice ts = args.toSlice();
        return ts.decode(address, uint32, address, uint256, mapping(uint32 => uint256), mapping(uint32 => uint256));
    }

    function encodeBorrowAddition(uint256 borrowAmount, address tip3Wallet, fraction index, uint32 marketId_) internal pure returns (TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.BORROW_FINALIZE);
        TvmBuilder op;
        op.store(borrowAmount);
        op.store(tip3Wallet);
        op.store(index);
        op.store(marketId_);
        tb.store(op.toCell());
        return tb.toCell();
    }

    function decodeBorrowAddition(TvmCell args) internal pure returns (uint256, address, fraction, uint32) {
        TvmSlice ts = args.toSlice();
        return ts.decode(uint256, address, fraction, uint32);
    }

    function createIndexUpdateRequest(address tonWallet, uint32 marketId, mapping (uint32=>bool) upd, address userTip3Wallet, uint256 amountToBorrow) internal pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.REQUEST_INDEX_UPDATE);
        TvmBuilder op;
        op.store(tonWallet);
        op.store(marketId);
        op.store(upd);
        op.store(userTip3Wallet);
        op.store(amountToBorrow);
        tb.store(op.toCell());
        return tb.toCell();
    }

    function decodeIndexUpdateRequest(TvmCell args) internal pure returns(address, uint32, mapping (uint32=>bool) upd, address userTip3Wallet, uint256 amountToBorrow) {
        TvmSlice ts = args.toSlice();
        return ts.decode(address, uint32, mapping (uint32=>bool), address, uint256);
    }

    function createIndexUpdateResponse(uint32 marketId, address userTip3Wallet, uint256 amountToBorrow, mapping (uint32=>bool) upd) internal pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(MarketOperationCodes.INDEX_UPDATE_RESPONSE);
        TvmBuilder op;
        op.store(marketId);
        op.store(userTip3Wallet);
        op.store(amountToBorrow);
        op.store(upd);
        tb.store(op);
        return tb.toCell();
    }
}