const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        userAM: true
    });

    let externalUpdatePayload = await contracts.userAccountManager.requestUserAccountHealthCalculation({
        tonWallet: '0:7028282fa0363d7e58fa1917071aa723931f033e4e421e15bde636ef570d1255'
    })

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(1, 'nano'),
        payload: externalUpdatePayload
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