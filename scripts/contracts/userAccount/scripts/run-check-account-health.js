const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        user: true
    });

    let payload = await contracts.userAccount.checkUserAccountHealth({
        gasTo: contracts.msigWallet.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccount.address,
        value: convertCrystal(4, 'nano'),
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