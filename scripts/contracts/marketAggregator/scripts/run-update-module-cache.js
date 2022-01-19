const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true
    });

    let payload = await contracts.marketsAggregator.updateModulesCache();

    await contracts.msigWallet.transfer({
        destination: contracts.marketsAggregator.address,
        value: convertCrystal(4, 'nano'),
        payload: payload
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