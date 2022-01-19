const { convertCrystal } = require('locklift/locklift/utils');
const { loadEssentialContracts } = require('../../../utils/contracts');

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true
    });

    await contracts.locklift.giver.giver.run({
        method: 'sendGrams',
        params: {
            dest: contracts.msigWallet.address,
            amount: convertCrystal(25, 'nano')
        }
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