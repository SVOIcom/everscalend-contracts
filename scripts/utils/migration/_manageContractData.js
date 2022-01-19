const fs = require('fs');
const { Locklift } = require("locklift/locklift");
const Contract = require('locklift/locklift/contract');
const configuration = require('../../scripts.conf');

/**
 * @typedef ContractData
 * @type {Object}
 * @property {String} name
 * @property {String} address
 * @property {Object} keyPair
 * @property {String} network
 */

/**
 * Creates data required to use the contract later
 * @param {Contract} contract 
 * @param {Object} configuration
 * @returns {ContractData}
 */
function createContractData(contract, configuration) {
    /**
     * @type {ContractData}
     */
    let contractData = {};
    contractData.name = contract.name;
    contractData.address = contract.address;
    contractData.keyPair = contract.keyPair;
    contractData.network = configuration.network;
    return contractData;
}

/**
 * 
 * @param {Locklift} locklift 
 * @param {import('../../scripts.conf').ScriptConfiguration} config
 * @param {ContractData} contractData
 */
async function loadContractFromData(locklift, config, contractData) {
    let contract = await locklift.factory.getContract(contractData.name, config.buildDirectory);
    if (contractData.network == config.network) {
        contract.setAddress(contractData.address);
        if (contractData.keyPair) {
            contract.setKeyPair(contractData.keyPair);
        }
    }

    return contract;
}

/**
 * 
 * @param {Contract} contract 
 * @param {String} filename
 * @returns {String}
 */
function writeContractData(contract, filename) {
    let resultFilename = `${configuration.deployedContractsDir}/${configuration.network}_${filename}.json`;
    fs.writeFileSync(resultFilename, JSON.stringify(createContractData(contract, configuration), null, '\t'));
    return resultFilename;
}

/**
 * 
 * @param {Locklift} locklift 
 * @param {String} filename 
 * @returns 
 */
async function loadContractData(locklift, filename) {
    let data = JSON.parse(fs.readFileSync(`${configuration.deployedContractsDir}/${configuration.network}_`+filename + '.json'));
    return loadContractFromData(locklift, configuration, data);
}

module.exports = {
    createContractData,
    loadContractFromData,
    writeContractData,
    loadContractData
}