const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({walletC: true});

    console.log(`Real token roots: ${pp(await contracts.walletController.getRealTokenRoots())}`);

    console.log(`Wallets: ${pp(await contracts.walletController.getWallets())}`);

    console.log(`Market addresses: ${pp(await contracts.walletController.getMarketAddresses({marketId: 0}))}`);

    console.log(`All markets: ${pp(await contracts.walletController.getAllMarkets())}`);

    console.log(`Code version: ${await contracts.walletController.contractCodeVersion()}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)