const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        deployer: true
    });

    console.log(`Contract codes:`);
    console.log(await contracts.tip3Deployer.getServiceInfo());
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)