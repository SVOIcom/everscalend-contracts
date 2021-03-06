const configuration = require("../../../scripts.conf");
const { fraction } = require("../../../utils/common");

// 1000000000

/**
 * @typedef MarketParams
 * @type {Object}
 * @property {Number} marketId
 * @property {String} realToken
 * @property {import("./marketsAggregatorWrapper").Fraction} _baseRate
 * @property {import("./marketsAggregatorWrapper").Fraction} _utilizationMultiplier
 * @property {import("./marketsAggregatorWrapper").Fraction} _reserveFactor
 * @property {import("./marketsAggregatorWrapper").Fraction} _exchangeRate
 * @property {import("./marketsAggregatorWrapper").Fraction} _collateralFactor
 * @property {import("./marketsAggregatorWrapper").Fraction} _liquidationMultiplier
 */

/**
 * 
 * @returns {MarketParams[]}
 */
function marketsToAdd() {
    if (configuration.network == 'devnet') {
        return [{
            marketId: 0,
            realToken: '0:6b3c699fb211e2b5b748fdbcf7757189ac112181e7baa0c2a0a0e13637eb2b9a',
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(15, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(90, 100),
            _liquidationMultiplier: fraction(108, 100)
        }, {
            marketId: 1,
            realToken: '0:dc17ff278222c4d40debea3b87894de8ed28205ab0a5b20968b29b1e26f2007a',
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(30, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(25, 100),
            _liquidationMultiplier: fraction(108, 100)
        }]
    } else if (configuration.network == 'local') {
        return [{
            marketId: 0,
            realToken: '0:4c5e140ec14fbbd394232568af191b756970bf36b30600e397b30b3e70b0b7b5',
            _baseRate: fraction(5, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(2, 1 * (365*24*60*60)),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(30, 100),
            _liquidationMultiplier: fraction(105, 100)
        }, {
            marketId: 1,
            realToken: '0:31f9de039b534e67db86186bc44b35c4cf64a3e577ff1aef52447233ddb85ee7',
            _baseRate: fraction(10, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(2, 1 * (365*24*60*60)),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(10, 1),
            _collateralFactor: fraction(30, 100),
            _liquidationMultiplier: fraction(105, 100)
        }]
    } else if (configuration.network == 'mainnet') {
        return [{
            marketId: 0,
            realToken: '0:a519f99bb5d6d51ef958ed24d337ad75a1c770885dcd42d51d6663f9fcdacfb2',
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(15, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(90, 100),
            _liquidationMultiplier: fraction(108, 100)
        }, {
            marketId: 1,
            realToken: '0:a49cd4e158a9a15555e624759e2e4e766d22600b7800d891e46f9291f044a93d',
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(30, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(25, 100),
            _liquidationMultiplier: fraction(108, 100)
        }]
    }
}

module.exports = {
    marketsToAdd
};