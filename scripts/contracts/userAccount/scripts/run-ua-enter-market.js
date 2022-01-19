const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { userMarketToEnter } = require("../modules/config");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        user: true
    });

    let availableMarkets = await contracts.marketsAggregator.getAllMarkets();

    for (let marketId in availableMarkets) {
        console.log(`Entering market ${marketId} with real token root ${availableMarkets[marketId].token}`);
        let payload = await contracts.userAccount.enterMarket({marketId});

        await contracts.msigWallet.transfer({
            destination: contracts.userAccount.address,
            value: convertCrystal(3, 'nano'),
            payload
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