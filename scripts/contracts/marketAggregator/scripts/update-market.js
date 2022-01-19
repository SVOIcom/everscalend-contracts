const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true
    });

    let updatePayload = await contracts.marketsAggregator.upgradeContractCode({
        code: contracts.marketsAggregator.code,
        updateParams: '',
        codeVersion: Number(await contracts.marketsAggregator.contractCodeVersion()) + 1
    });

    await contracts.msigWallet.transfer({
        destination: contracts.marketsAggregator.address,
        value: convertCrystal(1, 'nano'),
        payload: updatePayload
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