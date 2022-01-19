const { deployContract, loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    await deployContract({
        contractName: 'TIP3Deployer',
        constructorParams: {
            _owner: contracts.msigWallet.address
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