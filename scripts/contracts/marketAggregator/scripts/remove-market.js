const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true
    });

    let payload = await contracts.marketsAggregator.removeMarket({
        marketId: 1
    });

    await contracts.msigWallet.transfer({
        destination: contracts.marketsAggregator.address,
        payload
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