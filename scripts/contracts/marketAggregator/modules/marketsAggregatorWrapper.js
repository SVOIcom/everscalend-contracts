const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

/**
 * @typedef Fraction
 * @type {Object}
 * @property {Number} nom
 * @property {Number} denom
 */

class MarketsAggregator extends ContractTemplate {
    async updateModulesCache() {
        return await encodeMessageBody({
            contract: this,
            functionName: 'updateModulesCache',
            input: {}
        });
    }

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
    };

    async getServiceContractAddresses() {
        return await this.call({
            method: 'getServiceContractAddresses',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getTokenPrices() {
        return await this.call({
            method: 'getTokenPrices',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async getMarketInformation({marketId}) {
        return await this.call({
            method: 'getMarketInformation',
            params: {
                marketId 
            },
            keyPair: this.keyPair
        });
    }

    async getAllMarkets() {
        return await this.call({
            method: 'getAllMarkets',
            params: {},
            keyPair: this.keyPair
        });
    }

    async withdrawExtraTons() {
        return await encodeMessageBody({
            contract: this,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }

    async getAllModules() {
        return await this.call({
            method: 'getAllModules',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} p
     * @param {Number} p.marketId
     * @param {String} p.realToken
     * @param {Fraction} p._baseRate
     * @param {Fraction} p._utilizationMultiplier
     * @param {Fraction} p._reserveFactor
     * @param {Fraction} p._exchangeRate
     * @param {Fraction} p._collateralFactor
     * @param {Fraction} p._liquidationMultiplier
     */
    async createNewMarket({
        marketId,
        realToken,
        _baseRate,
        _utilizationMultiplier,
        _reserveFactor,
        _exchangeRate,
        _collateralFactor,
        _liquidationMultiplier
    }) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'createNewMarket',
            input: {
                marketId,
                realToken,
                _baseRate,
                _utilizationMultiplier,
                _reserveFactor,
                _exchangeRate,
                _collateralFactor,
                _liquidationMultiplier
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

    async forceUpdateAllPrices() {
        return await encodeMessageBody({
            contract: this,
            functionName: 'forceUpdateAllPrices',
            input: {}
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

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._tip3WalletController
     */
    async setWalletController({_tip3WalletController}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setWalletController',
            input: {
                _tip3WalletController
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._oracle
     */
    async setOracleAddress({_oracle}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setOracleAddress',
            input: {
                _oracle
            }
        });
    }

    async getOwner() {
        return await this.call({
            method: 'getOwner',
            params: {},
            keyPair: this.keyPair
        })
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.newOwner
     */
    async transferOwnership({newOwner}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'transferOwnership',
            input: {
                newOwner
            }
        });
    }

    async contractCodeVersion() {
        return this.call({
            method: 'contractCodeVersion',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @returns 
     */
    async removeMarket({marketId}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'removeMarket',
            input: {
                marketId
            }
        })
    }
}

module.exports = {
    MarketsAggregator
}