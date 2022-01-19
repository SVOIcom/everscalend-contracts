const Contract = require("locklift/locklift/contract");

/**
 * @classdesc Intreface for Giver contract. Use extendContractToGiver to gain real functionality
 * @class
 * @name Giver
 * @augments Contract
 */
class Giver extends Contract {
    /**
     * 
     * @param {String} destination Address to send grams to
     * @param {String} amount Amount in nanotons to send
     * @returns {Promise<Object>} result of operation
     */
    async sendGrams(destination, amount) {}
}


/**
 * Add Giver functionality to Contract instance
 * @param {Contract} contract 
 * @returns {Giver}
 */
function extendContractToGiver(contract) {
    contract.sendGrams = async function(destination, amount) {
        return await contract.run({
            method: 'sendGrams',
            params: {
                dest: destination,
                amount: amount
            },
            keyPair: contract.keyPair
        });
    }

    return contract;
}

module.exports = extendContractToGiver;