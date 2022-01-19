pragma ton-solidity >= 0.39.0;

library MarketMath {
    function calculateUtilizationRate(uint256 currentPool, uint256 totalBorrowed) internal pure returns (uint256) {

    }

    function calculateBorrowingRate(uint256 currentPool, uint256 totalBorrowed, uint256 totalReserves, uint256 totalSupply) 
        internal pure returns (uint256) 
    {

    }

    function calculateExchangeRate(uint256 currentPool, uint256 totalBorrowed, uint256 totalReserves, uint256 totalSupply)
        internal pure returns (uint256) 
    {
        return math.div(currentPool - totalReserves + totalBorrowed, totalSupply);
    }

    function recalculateState(uint256 currentPool, uint256 totalBorrowed, uint256 totalReserves, uint256 totalSupply)
        internal pure returns ()
    {
        // uint256 exchangeRate = calculateExchangeRate(currentPool, totalBorrowed, totalReserves, totalSupply);
    }
}