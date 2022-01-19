const { convertCrystal, zeroAddress } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");
const { Tip3Wallet } = require("../modules/tip3WalletWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        walletC: true
    });

    let realTip3 = new Tip3Wallet(await loadContractData(contracts.locklift, 'RealTip3'));

    let supllyModuleInfo = await contracts.walletController.getMarketAddresses({
        marketId: 0
    });

    let supplyPayload = await contracts.walletController.createSupplyPayload();

    let transferPayload = await realTip3.transfer({
        to: supllyModuleInfo.realTokenWallet,
        tokens: 10000e9,
        grams: 0,
        send_gas_to: zeroAddress,
        notify_receiver: true,
        payload: supplyPayload
    });

    await contracts.msigWallet.transfer({
        destination: realTip3.address,
        value: convertCrystal(10, 'nano'),
        bounce: false,
        payload: transferPayload
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