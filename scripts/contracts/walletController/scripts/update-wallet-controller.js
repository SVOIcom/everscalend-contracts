const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        walletC: true
    });

    let updatePayload = await contracts.walletController.upgradeContractCode({
        code: contracts.walletController.code,
        updateParams: '',
        codeVersion: Number(await contracts.walletController.contractCodeVersion()) + 1
    });

    await contracts.msigWallet.transfer({
        destination: contracts.walletController.address,
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