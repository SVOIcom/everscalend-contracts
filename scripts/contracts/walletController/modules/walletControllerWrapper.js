const { encodeMessageBody } = require("../../../utils/common");
const { ContractTemplate } = require("../../../utils/migration/_contractTemplate");

class WalletController extends ContractTemplate {
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
     * @param {Number} param0.marketId
     * @param {String} param0.realTokenRoot
     */
    async addMarket({marketId, realTokenRoot}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'addMarket',
            input: {
                marketId,
                realTokenRoot
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.marketId
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

    async getRealTokenRoots() {
        return await this.call({
            method: 'getRealTokenRoots',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getWallets() {
        return await this.call({
            method: 'getWallets',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0
     * @param {Number} param0.marketId
     */
    async getMarketAddresses({marketId}) {
        return await this.call({
            method: 'getMarketAddresses',
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

    async createSupplyPayload() {
        return await this.call({
            method: 'createSupplyPayload',
            params: {},
            keyPair: this.keyPair
        });
    }

    async createRepayPayload() {
        return await this.call({
            method: 'createRepayPayload',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.targetUser
     */
    async createLiquidationPayload({targetUser}) {
        return await this.call({
            method: 'createLiquidationPayload',
            params: {
                targetUser
            },
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
}

module.exports = {
    WalletController
}