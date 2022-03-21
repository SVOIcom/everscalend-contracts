const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

const config = [
    {
        marketId: 0,
        vTokenAddress: ''
    },
    {
        marketId: 1,
        vTokenAddress: ''
    }
]

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        marketModules: true
    });

    for (let currentMarket of config) {
        const payload = await contracts.modules.conversion.setMarketToken({
            marketId: currentMarket.marketId,
            vTokenAddress: currentMarket.vTokenAddress
        })

        await contracts.msigWallet.transfer({
            destination: contracts.modules.conversion.address,
            value: convertCrystal('3', 'nano'),
            payload
        })
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