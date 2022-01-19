const configuration = require('../../../scripts.conf');
const extendContractToGiver = require("../modules/GiverWrapper");
const initializeLocklift = require("../../../utils/initializeLocklift");
const { writeContractData } = require('../../../utils/migration');
const { loadEssentialContracts, deployContract } = require('../../../utils/contracts');
const { convertCrystal } = require('locklift/locklift/utils');



async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true
    });
    let giver = await contracts.locklift.factory.getContract('Giver', configuration.buildDirectory);
    const {
        address,
    } = await contracts.locklift.ton.createDeployMessage({
        contract: giver,
        constructorParams: {},
        initParams: {},
        keyPair: contracts.msigWallet.keyPair,
    });

    await contracts.msigWallet.transfer({
        destination: address,
        value: convertCrystal(5, 'nano'),
        payload: ''
    })

    await contracts.locklift.ton.client.net.wait_for_collection({
        collection: 'accounts',
        filter: {
        id: { eq: address },
        balance: { gt: `0x0` }
        },
        result: 'balance'
    });
    
    // Send deploy transaction
    const message = await contracts.locklift.ton.createDeployMessage({
        contract: giver,
        constructorParams: {},
        initParams: {},
        keyPair: contracts.msigWallet.keyPair,
    });
    
    await contracts.locklift.ton.waitForRunTransaction({ message, abi: giver.abi });
    
    giver.setAddress(address);

    await writeContractData(giver, 'Giver');
}

main().then(
    () => process.exit(0)
).catch((err) => {
    console.log(err);
    process.exit(1);
})