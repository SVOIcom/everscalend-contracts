const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class Module extends ContractTemplate {

    async sendActionId() {
        return await this.call({
            method: 'sendActionId',
            params: {},
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

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._marketAddress
     */
    async setMarketAdress({_marketAddress}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setMarketAddress',
            input: {
                _marketAddress
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._userAccountManager
     */
    async setUserAccountManager({_userAccountManager}) {
        return await encodeMessageBody({
            contract: this, 
            functionName: 'setUserAccountManager',
            input: {
                _userAccountManager
            }
        });
    }

    async getContractAddresses() {
        return await this.call({
            method: 'getContractAddresses',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getModuleState() {
        return await this.call({
            method: 'getModuleState',
            params: {},
            keyPair: this.keyPair
        });
    }

    async ownerGeneralUnlock({_locked}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'ownerGeneralUnlock',
            input: {
                _locked
            }
        });
    }

    async ownerUserUnlock({_user, _locked}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'ownerUserUnlock',
            input: {
                _user,
                _locked
            }
        });
    }

    async getGeneralLock() {
        return await this.call({
            method: 'getGeneralLock',
            params: {},
            keyPair: this.keyPair
        });
    }

    async userLock({user}) {
        return await this.call({
            method: 'userLock',
            params: {
                user
            },
            keyPair: this.keyPair
        })
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     * @returns 
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

    async contractCodeVersion() {
        return await this.call({
            method: 'contractCodeVersion',
            params: {},
            keyPair: this.keyPair
        });
    }
}

module.exports = {
    Module
}