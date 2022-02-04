const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true
    });

    for (let marketId = 0; marketId <= 1; marketId ++) {
        console.log(`Deleting market: ${marketId}`);
        let payload = await contracts.marketsAggregator.removeMarket({
            marketId
        });

        await contracts.msigWallet.transfer({
            destination: contracts.marketsAggregator.address,
            payload
        });
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)