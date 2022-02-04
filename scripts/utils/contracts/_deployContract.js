const Contract = require("locklift/locklift/contract");
const tryToExtractAddress = require("../../errorHandler/errorHandler");
const configuration = require("../../scripts.conf");
const { loadEssentialContracts } = require("./_loadEssentialContracts");
const { writeContractData } = require("../migration");
const { convertCrystal } = require("locklift/locklift/utils");


/**
 * 
 * @param {Object} p 
 * @param {String} p.contractName
 * @param {Object} p.constructorParams
 * @param {Object} p.initParams
 * @returns {Promise<Contract>}
 */
async function deployContract({
    contractName,
    constructorParams = {},
    initParams = {}
}) {
    let contracts = await loadEssentialContracts({
        wallet: true
    });

    let contractToDeploy = await contracts.locklift.factory.getContract(contractName, configuration.buildDirectory);
    try {
        await contracts.locklift.giver.deployContract({
            contract: contractToDeploy,
            constructorParams,
            initParams,
            keyPair: contracts.msigWallet.keyPair,
        }, convertCrystal(2, 'nano'));
        console.log(`Contract was deployed at address: ${contractToDeploy.address}`);
    } catch (err) {
        let address = tryToExtractAddress(err);
        if (address) {
            contractToDeploy.setAddress(address);
            console.log(`Contract already deployed at address: ${contractToDeploy.address}`);
        } else {
            console.log(err);
        }
    }

    if (contractToDeploy.address) {
        contractToDeploy.setKeyPair(contracts.msigWallet.keyPair);
        let filename = writeContractData(contractToDeploy, contractToDeploy.name);
        console.log(`Data is written to file: ${filename}`);
    }

    return contractToDeploy;
}

module.exports = deployContract;