const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        userAM: true
    });

    let externalUpdatePayload = await contracts.userAccountManager.requestUserAccountHealthCalculation({
        tonWallet: '0:4b00ac10bd8b212dca0b8ab54acffea1eede2eff0fae10249a0548943a3033d1'
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