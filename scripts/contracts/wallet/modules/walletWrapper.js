const { convertCrystal } = require('locklift/locklift/utils');
const { operationFlags } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class MsigWallet extends ContractTemplate {
    /**
     * Transfer TONs to specified destination
     * @param {Object} p
     * @param {String} p.destination 
     * @param {String} p.value 
     * @param {Number} p.flags 
     * @param {Boolean} p.bounce
     * @param {String} p.payload 
     */
    async transfer({destination, value = convertCrystal(1, 'nano'), flags = operationFlags.FEE_FROM_CONTRACT_BALANCE, bounce = false, payload}) {
        return await this.run({
            method: 'sendTransaction',
            params: {
                dest: destination,
                value: value,
                bounce: bounce,
                flags: flags,
                payload: payload
            },
            keyPair: this.keyPair
        })
    }
}

module.exports = {
    MsigWallet
}