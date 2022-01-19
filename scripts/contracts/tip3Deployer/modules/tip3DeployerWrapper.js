const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

/**
 * @class
 * @name TIP3Deployer
 */
class TIP3Deployer extends ContractTemplate {
    /**
     * Deploy TIP-3 token
     * @param {Object} p
     * @param {Object} p.rootInfo 
     * @param {String} p.deployGrams 
     * @param {String} p.pubkeyToInsert 
     */
    async deployTIP3({rootInfo, deployGrams, pubkeyToInsert}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'deployTIP3',
            input: {
                _answer_id: 0,
                rootInfo: rootInfo,
                deployGrams: deployGrams,
                pubkeyToInsert: pubkeyToInsert
            }
        });
    }

    /**
     * Get future address of TIP-3 token with given parameters
     * @param {Object} p
     * @param {Object} p.rootInfo 
     * @param {String} p.pubkeyToInsert 
     */
    async getFutureTIP3Address({rootInfo, pubkeyToInsert}) {
        return await this.call({
            method: 'getFutureTIP3Address',
            params: {
                rootInfo: rootInfo,
                pubkeyToInsert: pubkeyToInsert
            },
            keyPair: this.keyPair
        });
    }

    /**
     * Set RootTokenContract code
     * @param {Object} p
     * @param {String} p._rootContractCode 
     */
    async setTIP3RootContractCode({_rootContractCode}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setTIP3RootContractCode',
            input: {
                _rootContractCode: _rootContractCode
            }
        });
    }

    /**
     * Set TONTokenWallet code
     * @param {Object} p
     * @param {String} p._walletContractCode 
     */
    async setTIP3WalletContractCode({_walletContractCode}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setTIP3WalletContractCode',
            input: {
                _walletContractCode: _walletContractCode
            }
        });
    }

    /**
     * Fetch RootTokenContract and TONTokenWallet codes
     */
    async getServiceInfo() {
        return await this.call({
            method: 'getServiceInfo',
            params: {},
            keyPair: this.keyPair
        });
    }
}

module.exports = {
    TIP3Deployer
}