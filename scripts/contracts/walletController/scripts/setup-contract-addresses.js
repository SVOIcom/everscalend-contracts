const { convertCrystal } = require("locklift/locklift/utils");
const { operationFlags } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        userAM: true,
        walletC: true
    });

    let marketPayload = await contracts.walletController.setMarketAddress({
        _market: contracts.marketsAggregator.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.walletController.address,
        payload: marketPayload
    });
    
    console.log('Contract addresses for WalletController set');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)