const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true, 
        userAM: true
    });

    let updatePayload = await contracts.userAccountManager.upgradeContractCode({
        code: contracts.userAccountManager.code,
        updateParams: '',
        codeVersion: Number(await contracts.userAccountManager.contractCodeVersion()) + 1
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
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