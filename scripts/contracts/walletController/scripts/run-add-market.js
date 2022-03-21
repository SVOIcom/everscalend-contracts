const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        walletC: true,
        walletCVersion: 2
    });

    let allMarketInfo = await contracts.marketsAggregator.getAllMarkets();

    for (let marketId in allMarketInfo) {
        let marketInfo = allMarketInfo[marketId];
        
        let addMarketPayload = await contracts.walletController.addMarket({
            marketId: marketId,
            realTokenRoot: marketInfo.token
        });
    
        await contracts.msigWallet.transfer({
            destination: contracts.walletController.address,
            value: convertCrystal(10, 'nano'),
            payload: addMarketPayload
        });
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)