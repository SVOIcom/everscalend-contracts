const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");
const { Tip3Wallet } = require("../../wallet/modules/tip3WalletWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        user: true
    });
    
    let realTip3 = new Tip3Wallet(await loadContractData(contracts.locklift, 'RealTip3'));

    let payload = await contracts.userAccount.withdraw({
        userTip3Wallet: realTip3.address,
        marketId: 0,
        tokensToWithdraw: 9900000000000
    });

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