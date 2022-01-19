const { loadEssentialContracts, deployContract } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    let modules = ['SupplyModule', 'BorrowModule', 'RepayModule', 'WithdrawModule', 'LiquidationModule'];
    let constructorParams = {
        _newOwner: contracts.msigWallet.address
    };
    for (let contractName of modules) {
        await deployContract({
            contractName,
            constructorParams
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