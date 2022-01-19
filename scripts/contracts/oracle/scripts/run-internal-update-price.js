const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        oracle: true, 
        wallet: true,
        testSP: true,
        market: true
    });

    let allMarketInfo = await contracts.marketsAggregator.getAllMarkets();

    let marketInfo = await contracts.marketsAggregator.getMarketInformation({
        marketId: 1
    });

    let internalUpdatePayload = await contracts.oracle.internalUpdatePrice({
        tokenRoot: marketInfo.token
    });

    await contracts.msigWallet.transfer({
        destination: contracts.oracle.address,
        value: convertCrystal(2, 'nano'),
        payload: internalUpdatePayload
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