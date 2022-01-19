pragma ton-solidity >= 0.39.0;

import "../../utils/libraries/FloatingPointOperations.sol";

library MarketOperations {
    using UFO for uint256;
    using FPO for fraction;

    function calculateU(uint256 totalBorrowed, uint256 realTokens) internal pure returns (fraction) {
        return fraction(totalBorrowed, totalBorrowed + realTokens);
    }

    function calculateBorrowInterestRate(fraction baseRate, uint256 realTokenBalance, uint256 totalBorrowed, fraction utilizationMultiplier) internal returns (fraction) {
        fraction bir;

        fraction utilizationRate = fraction(totalBorrowed, totalBorrowed + realTokenBalance);

        bir = utilizationRate.fMul(utilizationMultiplier);
        bir = bir.fAdd(baseRate);

        return bir;
    }

    function calculateExchangeRate(uint256 currentPoolBalance, uint256 totalBorrowed, uint256 totalReserve, uint256 vTokenSupply) internal pure returns(fraction) {
        return fraction(currentPoolBalance + totalBorrowed - totalReserve, vTokenSupply);
    }

    function calculateTotalReserves(uint256 totalReserve, uint256 totalBorrowed, fraction r, fraction reserveFactor, uint256 t) internal returns (fraction) {
        fraction tr;
        tr = r.fNumMul(t);
        tr = tr.fMul(reserveFactor);
        tr = tr.fNumMul(totalBorrowed);
        tr = tr.fNumAdd(totalReserve);
        return tr;
    }

    function calculateNewIndex(fraction index, fraction bir, uint256 dt) internal returns (fraction) {
        fraction index_;
        index_ = bir.fNumMul(dt);
        index_ = index_.fNumAdd(1);
        index_ = index_.fAdd(index);
        return index_;
    }

    function calculateTotalBorrowed(uint256 totalBorrowed, fraction oldIndex, fraction newIndex) internal returns (uint256) {
        fraction tb_;
        tb_ = totalBorrowed.numFDiv(oldIndex);
        tb_ = tb_.fMul(newIndex);
        return tb_.toNum();
    }

    function calculateReserves(uint256 reserveOld, uint256 totalBorrowedOld, fraction bir, fraction reserveFactor, uint256 dt) internal returns (uint256) {
        fraction res = bir;
        res = res.fNumMul(dt);
        res = res.fMul(reserveFactor);
        res = res.fNumMul(totalBorrowedOld);
        res = res.fNumAdd(reserveOld);
        return res.toNum();
    }
}