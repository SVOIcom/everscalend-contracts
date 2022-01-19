const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    let payload = await contracts.userAccountManager.removeMarket({
        tonWallet: contracts.msigWallet.address,
        marketId: 0
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
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