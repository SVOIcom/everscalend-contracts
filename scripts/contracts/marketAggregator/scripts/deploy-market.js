const { loadEssentialContracts, deployContract } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    await deployContract({
        contractName: 'MarketsAggregator',
        constructorParams: {
            _newOwner: contracts.msigWallet.address
        },
        initParams: {}
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