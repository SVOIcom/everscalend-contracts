const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");
const { Tip3Wallet } = require("../../wallet/modules/tip3WalletWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        user: true
    });

    contracts.msigWallet.address = '0:d4668ff0e7151d274626bb3ac242ccc825212abeac86614f408ab30c8a90b032';
    contracts.msigWallet.keyPair.public = '63c5234cf6970764b0986b34891686e56e8adeaa46a0d321f9a601fdebb8cbc8';
    contracts.msigWallet.keyPair.secret = '3966d025bae66e57100f7b12ae16d960312e253ca69b85c7e1c3cbae640673b8';

    contracts.userAccount.address = '0:6efc1a3095271096c4c5f87255772b9d1951c652d8687e33185ecbfc9e0d7ce3';

    let payload = await contracts.userAccount.withdrawExtraTons();

    await contracts.msigWallet.transfer({
        destination: contracts.userAccount.address,
        value: convertCrystal(5, 'nano'),
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