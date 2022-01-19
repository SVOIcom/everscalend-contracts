const Contract = require("locklift/locklift/contract");
const { pp } = require("./common");
const { loadEssentialContracts } = require("./contracts");

/**
 * 
 * @param {String} address 
 * @param {Object} contractPool 
 * @returns {Contract}
 */
function findContractByAddress(address, contractPool) {
    let resultContract = undefined;
    for (let contractName in contractPool) {
        /**
         * @type {Contract}
         */
        let contract = contractPool[contractName];
        if (contract?.address == address) {
            resultContract = contractPool[contractName];
        }
    }
    return resultContract;
}

function createMessagesFilter(incoming, contractAddress) {
    let filter = {};
    if (incoming) {
        filter.dst = {
            eq: contractAddress
        }
    } else {
        filter.src = {
            eq: contractAddress
        }
    }
    return filter;
}

async function main() {
    let args = process.argv.slice(2);
    let contractAddress = args[0];
    let incoming = args[1] == 'in';

    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        oracle: true,
        userAM: true,
        walletC: true,
        testSP: true,
        user: true
    });

    let modules = (await loadEssentialContracts({
        marketModules: true
    })).modules;

    let contractToUse = findContractByAddress(contractAddress, contracts);
    if (!contractToUse) {
        contractToUse = findContractByAddress(contractAddress, modules);
    }

    if (!contractToUse) {
        console.log(`Cannot find contract with address ${contractAddress}`);
        process.exit(1);
    }

    let messages = undefined;
    try {
        messages = await contracts.locklift.ton.client.net.query_collection({
            collection: 'messages',
            filter: createMessagesFilter(incoming, contractAddress),
            order: [{
                path: 'created_lt',
                direction: 'DESC'
            }],
            result: "id created_lt msg_type status src dst value boc body"
        });
    } catch (err) {
        console.log(err);
        console.log(`Cannot fetch messages for contract ${contractToUse.name} with address ${contractAddress}`);
    }

    for (let message of messages.result) {
        try {
            let result = await contracts.locklift.ton.client.abi.decode_message_body({
                body: message.body,
                is_internal: true,
                abi: {
                    type: 'Contract',
                    value: contractToUse.abi
                }
            });
            console.log(`Time: ${Number(message.created_lt)}`);
            console.log(pp(result));
        } catch(err) {
            console.log(err);
            console.log('Cannot decode message');
        }
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)