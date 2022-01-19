const { loadEssentialContracts, deployContract } = require("../../../utils/contracts");

async function main() {
    await deployContract({
        contractName: 'TestSwapPair',
        initParams: {
            nonce: 0
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