const secondsPerYear = 365 * 24 * 60 * 60;

/**
 * @typedef BorrowInfo
 * @type {Object}
 * @property {String} tokensBorrowed
 * @property {Fraction} index
 */

/**
 * @typedef Fraction
 * @type {Object}
 * @property {String} nom
 * @property {String} denom
 */

/**
 * @typedef MarketInfo
 * @type {Object}
 * @property {String} token
 * @property {String} realTokenBalance
 * @property {String} vTokenBalance
 * @property {String} totalBorrowed
 * @property {String} totalReserve
 * @property {Fraction} index
 * @property {Fraction} baseRate
 * @property {Fraction} utilizationMultiplier
 * @property {Fraction} reserveFactor
 * @property {Fraction} exchangeRate
 * @property {Fraction} collateralFactor
 * @property {Fraction} liquidationMultiplier
 * @property {String} lastUpdateTime
 */

/**
 * @typedef AllMarketsInfo
 * @type {Record<String, MarketInfo>}
 */

/**
 * @typedef UserMarketInfo
 * @type {Object}
 * @property {Boolean} exists
 * @property {Number} _marketId
 * @property {String} suppliedTokens
 * @property {Fraction} getAccountHealth
 * @property {BorrowInfo} borrowInfo
 */

/**
 * @typedef UserInfo
 * @type {Record<String, UserMarketInfo>}
 */

/**
 * @typedef Prices
 * @type {Record<String, Fraction>}
 */

/**
 * 
 * @param {Fraction} f 
 * @returns 
 */
function f(f) {
    return Number(f.nom) / Number(f.denom);
}

/**
 * @param {Object} param0 
 * @param {AllMarketsInfo} param0.markets
 * @param {UserInfo} param0.userInfo
 * @param {Prices} param0.prices
 */
function getUSDBorrowed({
    markets,
    userInfo,
    prices
}) {
    let borrowedSum = 0;
    for (let marketId in userInfo) {
        borrowedSum += 
            Number(userInfo[marketId].borrowInfo.tokensBorrowed) / 
            f(userInfo[marketId].borrowInfo.index) *
            f(markets[marketId].index) / 
            f(prices[markets[marketId].token]);
    }

    return borrowedSum;
}

/**
 * @param {Object} param0 
 * @param {AllMarketsInfo} param0.markets
 * @param {UserInfo} param0.userInfo
 * @param {Prices} param0.prices
 */
function getUSDCollateral({
    markets,
    userInfo,
    prices
}) {
    let collateral = 0;
    for (let marketId in userInfo) {
        collateral += 
            Number(userInfo[marketId].suppliedTokens) * 
            f(markets[marketId].exchangeRate) /
            f(prices[markets[marketId].token]) *
            f(markets[marketId].collateralFactor);
    }
    return collateral;
}


/**
 * @param {Object} param0 
 * @param {AllMarketsInfo} param0.markets
 * @param {UserInfo} param0.userInfo
 * @param {Prices} param0.prices
 * @returns {Record<Number, Number>}
 */
function tokensAvailableForWithdrawal({
    userInfo,
    markets,
    prices
}) {
    let collateral = getUSDCollateral({userInfo, markets, prices});
    
    let borrowed = getUSDBorrowed({userInfo, markets, prices});
    
    let deltaUSD = collateral - borrowed;
    let possibleWithdraw = {};
    for (let marketId in userInfo) {
        if (collateral > borrowed && Number(userInfo[marketId].suppliedTokens) > 0) {
            let maxTokensForWithdraw = deltaUSD * f(prices[markets[marketId].token]) / f(markets[marketId].exchangeRate) / f(markets[marketId].collateralFactor);
            possibleWithdraw[Number(marketId)] = Math.min(maxTokensForWithdraw, Number(userInfo[marketId].suppliedTokens));
        } else {
            possibleWithdraw[Number(marketId)] = 0;
        }
    }
    
    return possibleWithdraw;
}

/**
 * @param {Object} param0 
 * @param {AllMarketsInfo} param0.markets
 * @param {UserInfo} param0.userInfo
 * @param {Prices} param0.prices
 */
function getAccountHealth({
    markets,
    userInfo,
    prices
}) {
    let borrowedSum = getUSDBorrowed({markets, userInfo, prices});
    let suppliedSum = getUSDCollateral({markets, userInfo, prices});
    let usedPercentage = borrowedSum / suppliedSum;
    let accountHealth = (1 - usedPercentage) * 100;
    return accountHealth;
}

/**
 * 
 * @param {Object} param0 
 * @param {Number} param0.collateralValue
 * @param {Number} param0.borrowedValue
 * @param {Number} param0.tokenPrice
 */
function getPossibleBorrow({
    collateralValue, 
    borrowedValue,
    tokenPrice
}) {
    if (collateralValue > borrowedValue)
        return (collateralValue - borrowedValue) * tokenPrice;
    else
        return 0;
}

/**
 * 
 * @param {Object} param0 
 * @param {MarketInfo} param0.market
 */
function getCurrentBorrowRatePerDay({
    market
}) {
    return f(market.baseRate)*24*60*60 + Number(market.totalBorrowed) / (Number(market.totalBorrowed) + Number(market.realTokenBalance)) * f(market.utilizationMultiplier)*24*60*60;
}

/**
 *
 * @param {Object} param0
 * @param {MarketInfo} param0.market
 */
function getCurrentBorrowRate({
    market
}) {
    if((Number(market.totalBorrowed) + Number(market.realTokenBalance)) * f(market.utilizationMultiplier) === 0) {
        return 0;   
    }
    return getCurrentBorrowRatePerDay({market}) * 365;
}

/**
 * 
 * @param {Object} param0 
 * @param {MarketInfo} param0.market
 */
function getBorrowAPY({
    market
}) {
    let borrowRate = getCurrentBorrowRatePerDay({market});
    return (((Math.pow(borrowRate + 1, 365))) - 1) * 100;
}

module.exports = {
    getUSDBorrowed,
    getUSDCollateral,
    getAccountHealth,
    getPossibleBorrow,
    getBorrowAPY,
    getCurrentBorrowRatePerDay,
    getCurrentBorrowRate,
    f
}
