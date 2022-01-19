const { encodeMessageBody, pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true
    });

    let testContract = await loadContractData(contracts.locklift, 'TestSwapPair');

    let payload = await encodeMessageBody({
        contract: testContract,
        functionName: 'setBalances',
        input: {
            left: 100,
            right: 38,
            minted: 3810
        }
    });

    await contracts.msigWallet.transfer({
        destination: testContract.address,
        payload
    });

    console.log(`Current test swap pair state: ${pp(await testContract.call({method: 'getBalances', params: {}, keyPair: testContract.keyPair}))}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)