const { loadEssentialContracts } = require("../utils/contracts");
const { getBorrowAPY, getCurrentBorrowRatePerDay, f } = require("./calculateDisplayedParameters")

/**
 * 
 * @param {import("./calculateDisplayedParameters").MarketInfo} param0 
 * @returns 
 */
function supplyRatePerBlock({market}) {
    if((market.vTokenBalance * market.exchangeRate) === 0) {
        return 0;
    }
    return getCurrentBorrowRatePerDay({market}) * (1 - f(market.reserveFactor)) * Number(market.totalBorrowed) / (Number(market.vTokenBalance) * f(market.exchangeRate))
}

function getSupplyAPY({market}) {
    return (Math.pow(supplyRatePerBlock({market}) + 1, 365) - 1) * 100
}


async function main() {
    let contracts = await loadEssentialContracts({market: true});

    /**
     * @type {import("./calculateDisplayedParameters").MarketInfo}
     */
    let marketInfo = await contracts.marketsAggregator.getMarketInformation({marketId: 0});

    let borrowRate = getCurrentBorrowRatePerDay({market: marketInfo});
    console.log(borrowRate)

    let borrowAPY = getBorrowAPY({
        market: marketInfo
    });
    console.log(borrowAPY);

    let supplyRate = supplyRatePerBlock({market: marketInfo});
    console.log(supplyRate);

    let supplyAPY = getSupplyAPY({market: marketInfo});
    console.log(supplyAPY);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
    }
)