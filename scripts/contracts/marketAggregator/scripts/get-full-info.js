const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

/**
 * 
 * @param {Fraction} f 
 * @returns 
 */
 function f(f) {
    return Number(f.nom) / Number(f.denom);
}

/**
 * 
 * @param {Object} param0 
 * @param {MarketInfo} param0.market
 */
 function getCurrentBorrowRate({
    market
}) {
    return f(market.baseRate) + Number(market.totalBorrowed) / (Number(market.totalBorrowed) + Number(market.realTokenBalance)) * f(market.utilizationMultiplier);
}

async function main() {
    let contracts = await loadEssentialContracts({market: true});

    console.log(`Owner address:`);
    console.log(await contracts.marketsAggregator.getOwner());

    console.log(`Service contract addresses:`);
    console.log(await contracts.marketsAggregator.getServiceContractAddresses());

    console.log(`Known token prices:`);
    console.log(await contracts.marketsAggregator.getTokenPrices());

    console.log(`All markets information:`);
    console.log(await contracts.marketsAggregator.getAllMarkets());

    console.log(`All modules:`);
    console.log(await contracts.marketsAggregator.getAllModules());

    console.log(`Token price info:`);
    console.log(await contracts.marketsAggregator.getTokenPrices());

    console.log(`Market 0 information:`);
    console.log(pp(await contracts.marketsAggregator.getMarketInformation({marketId: 0})));

    console.log(`Code version:`)
    console.log(await contracts.marketsAggregator.contractCodeVersion());
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)