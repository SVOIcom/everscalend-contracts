const { convertCrystal, zeroAddress } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");
const { Tip3Wallet } = require("../modules/tip3WalletWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        walletC: true
    });

    /**
     * @type {Tip3Wallet}
     */
    let realTip3 = new Tip3Wallet(await loadContractData(contracts.locklift, 'RealTip3'));

    let payload = await contracts.walletController.createRepayPayload();

    let supllyModuleInfo = await contracts.walletController.getMarketAddresses({
        marketId: 0
    });

    let tip3Payload = await realTip3.transfer({
        to: supllyModuleInfo.realTokenWallet,
        tokens: 100e9,
        send_gas_to: zeroAddress,
        payload
    });

    await contracts.msigWallet.transfer({
        destination: realTip3.address,
        value: convertCrystal(10, 'nano'),
        payload: tip3Payload
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