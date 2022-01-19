const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../../utils/common');

class UserAccountManager extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     */
    async upgradeContractCode({code, updateParams, codeVersion}) {
        return await encodeMessageBody({
            contract: this, 
            functionName: 'upgradeContractCode',
            input: {
                code,
                updateParams,
                codeVersion
            }
        });
    }

    /**
     * 
     * @param {Object} param0
     * @param {String} param0.tonWallet
     */
    async createUserAccount({tonWallet}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'createUserAccount',
            input: {
                tonWallet
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     */
    async calculateUserAccoutAddress({tonWallet}) {
        return await this.call({
            method: 'calculateUserAccountAddress',
            params: {
                tonWallet
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._market
     */
    async setMarketAddress({_market}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setMarketAddress',
            input: {
                _market
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.version
     * @param {String} param0.code
     */
    async uploadUserAccountCode({version, code}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'uploadUserAccountCode',
            input: {
                version,
                code
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     */
    async updateUserAccount({tonWallet}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'updateUserAccount',
            input: {
                tonWallet
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.operationId
     * @param {String} param0.module
     */
    async addModule({operationId, module}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'addModule',
            input: {
                operationId,
                module
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.operationId
     */
    async removeModule({operationId}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'removeModule',
            input: {
                operationId
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.version
     */
    async getUserAccountCode({version}) {
        return await this.call({
            method: 'getUserAccountCode',
            params: {
                version
            },
            keyPair: this.keyPair
        });
    }

    async getOwner() {
        return await this.call({
            method: 'getOwner',
            params: {},
            keyPair: this.keyPair
        });
    }

    async marketAddress() {
        return await this.call({
            method: 'marketAddress',
            params: {},
            keyPair: this.keyPair
        });
    }

    async modules() {
        return await this.call({
            method: 'modules',
            params: {},
            keyPair: this.keyPair
        });
    }

    async existingModules() {
        return await this.call({
            method: 'existingModules',
            params: {},
            keyPair: this.keyPair
        });
    }

    async userAccountCodes() {
        return await this.call({
            method: 'userAccountCodes',
            params: {},
            keyPair: this.keyPair
        });
    }

    async contractCodeVersion() {
        return await this.call({
            method: 'contractCodeVersion',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} tonWallet
     * @param {Number} marketId
     * @returns 
     */
    async removeMarket({tonWallet, marketId}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'removeMarket',
            input: {
                tonWallet,
                marketId
            }
        })
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     * @returns 
     */
    async disableUserAccountLock({tonWallet}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'disableUserAccountLock',
            input: {
                tonWallet
            }
        })
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     * @returns 
     */    
    async requestUserAccountHealthCalculation({tonWallet}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'requestUserAccountHealthCalculation',
            input: {
                tonWallet
            }
        })
    }
}

module.exports = {
    UserAccountManager
}