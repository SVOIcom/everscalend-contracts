const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        userAM: true
    });

    let externalUpdatePayload = await contracts.userAccountManager.requestUserAccountHealthCalculation({
        tonWallet: '0:60bc706a93d66f90c63203e185b6194c16c484d3fc8cccc91fd79d453465b11a'
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