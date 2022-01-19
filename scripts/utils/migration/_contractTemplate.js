const Contract = require("locklift/locklift/contract");

class ContractTemplate extends Contract {
    /**
     * 
     * @param {Contract} contract 
     */
    constructor(contract) {
        super({
            locklift: contract.locklift,
            abi: contract.abi,
            base64: contract.base64,
            code: contract.code,
            name: contract.name,
            address: contract.address,
            keyPair: contract.keyPair,
            autoAnswerIdOnCall: contract.autoAnswerIdOnCall,
            autoRandomNonce: contract.autoRandomNonce,
            afterRun: contract.afterRun
        });
    }
}

module.exports = {
    ContractTemplate
}