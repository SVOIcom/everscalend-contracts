const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true
    });

    let marketInfo = await contracts.marketsAggregator.getMarketInformation({
        marketId: 0
    });

    let updateTokenPayload = await contracts.marketsAggregator.forceUpdateAllPrices();

    await contracts.msigWallet.transfer({
        destination: contracts.marketsAggregator.address,
        value: convertCrystal(2, 'nano'),
        payload: updateTokenPayload
    });
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)