const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");
const tokenToAdd = require("../modules/tokenToAdd");

async function main() {
    let contracts = await loadEssentialContracts({
        oracle: true,
        market: true
    });

    console.log(`Contract version: ${pp(await contracts.oracle.getVersion())}`);

    console.log(`Contract details: ${pp(await contracts.oracle.getDetails())}`);

    console.log(`Token info: ${pp(await contracts.oracle.getTokenPrice({
        tokenRoot: (await contracts.marketsAggregator.getMarketInformation({marketId: 0})).token, 
        payload: ''
    }))}`);

    console.log(`All token info: ${pp(await contracts.oracle.getAllTokenPrices({payload: ''}))}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)