const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class Tip3Wallet extends ContractTemplate {
    async transfer({to, tokens, grams = 0, send_gas_to, notify_receiver = true, payload}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'transfer',
            input: {
                to,
                tokens,
                grams,
                send_gas_to,
                notify_receiver,
                payload
            }
        });
    }
}

module.exports = {
    Tip3Wallet
}