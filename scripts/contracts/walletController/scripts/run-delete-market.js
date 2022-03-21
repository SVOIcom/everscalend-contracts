const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        walletC: true,
        walletCVersion: 2
    });

    let payload = await contracts.walletController.removeMarket({
        marketId: 0
    });

    await contracts.msigWallet.transfer({
        destination: contracts.walletController.address,
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