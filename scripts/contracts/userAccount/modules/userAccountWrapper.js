const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class UserAccount extends ContractTemplate {
    async getOwner() {
        return await this.call({
            method: 'getOwner',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getKnownMarkets() {
        return await this.call({
            method: 'getKnownMarkets',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getAllMarketsInfo() {
        return await this.call({
            method: 'getAllMarketsInfo',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async getMarketInfo({marketId}) {
        return await this.call({
            method: 'getMarketInfo',
            params: {
                marketId
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0
     * @param {String} param0.userTip3Wallet
     * @param {Number} param0.marketId
     * @param {Number} param0.tokensToWithdraw
     * @returns {Promise<Object>}
     */
    async withdraw({userTip3Wallet, marketId, tokensToWithdraw}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'withdraw',
            input: {
                userTip3Wallet,
                marketId,
                tokensToWithdraw
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {Number} param0.amountToBorrow
     * @param {String} param0.userTip3Wallet
     */
    async borrow({marketId, amountToBorrow, userTip3Wallet}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'borrow',
            input: {
                marketId,
                amountToBorrow,
                userTip3Wallet
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.gasTo
     * @returns 
     */
    async checkUserAccountHealth({gasTo}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'checkUserAccountHealth',
            input: {
                gasTo
            }
        })
    }
    
    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async enterMarket({marketId}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'enterMarket',
            input: {
                marketId
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @returns 
     */
    async withdrawExtraTons() {
        return await encodeMessageBody({
            contract: this,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }

    async userAccountManager() {
        return await this.call({
            method: 'userAccountManager',
            params: {},
            keyPair: this.keyPair
        });
    }

    async accountHealth() {
        return await this.call({
            method: 'accountHealth',
            params: {},
            keyPair: this.keyPair
        });
    }

    async borrowLock() {
        return await this.call({
            method: 'borrowLock',
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
}

module.exports = {
    UserAccount
}