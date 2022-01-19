const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        oracle: true, 
        wallet: true,
        testSP: true,
        market: true
    });

    let allMarketInfo = await contracts.marketsAggregator.getAllMarkets();

    for (let marketId in allMarketInfo) {
        let addPayload = await contracts.oracle.addToken({
            tokenRoot: allMarketInfo[marketId].token,
            swapPairAddress: contracts.testSwapPair.address,
            isLeft: marketId % 2 == 0
        });

        await contracts.msigWallet.transfer({
            destination: contracts.oracle.address,
            payload: addPayload
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