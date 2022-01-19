const { loadEssentialContracts, deployContract } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    await deployContract({
        contractName: 'WalletController',
        constructorParams: {
            _newOwner: contracts.msigWallet.address
        }
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