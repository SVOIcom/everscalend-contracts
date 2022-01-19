const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        user: true,
    });

    let realTip3 = await loadContractData(contracts.locklift, 'RealTip3');

    let payload = await contracts.userAccount.borrow({
        marketId: 0,
        amountToBorrow: 1000e9,
        userTip3Wallet: realTip3.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccount.address,
        value: convertCrystal(10, 'nano'),
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