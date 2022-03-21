module.exports = {
    compiler: {
        // Specify path to your TON-Solidity-Compiler
        path: '/usr/bin/solc',
    },
    linker: {
        // Path to your TVM Linker
        path: '/usr/bin/tvm_linker',
    },
    networks: {
        // You can use TON labs graphql endpoints or local node
        local: {
            ton_client: {

                // See the TON client specification for all available options
                network: {
                    server_address: 'http://localhost:80/',
                    endpoints: ['http://localhost:80']
                },

                abi: {
                    message_expiration_timeout: 1200000
                }
            },
            // This giver is default local-node giver
            giver: {
                address: '0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94',
                abi: { "ABI version": 1, "functions": [{ "name": "constructor", "inputs": [], "outputs": [] }, { "name": "sendGrams", "inputs": [{ "name": "dest", "type": "address" }, { "name": "amount", "type": "uint64" }], "outputs": [] }], "events": [], "data": [] },
                key: '',
            },
            // Use tonos-cli to generate your phrase
            // !!! Never commit it in your repos !!!
            keys: {
                phrase: 'melody clarify hand pause kit economy bind behind grid witness cheap tomorrow',
                amount: 20,
            }
        },
        devnet: {
            ton_client: {
                // See the TON client specification for all available options
                network: {
                    server_address: 'net.ton.dev',
                    endpoints: ['net.ton.dev']
                },

                abi: {
                    message_expiration_timeout: 120000
                }
            },

            // This giver is default local-node giver
            giver: {
                address: '0:fb6dad745ff9f88597e5a3e7824b4030e91ade869464274ed808812edf6adaf3',
                abi: { "ABI version": 2, "header": ["time", "expire"], "functions": [ { "name": "constructor", "inputs": [ ], "outputs": [ ] }, { "name": "sendGrams", "inputs": [ {"name":"dest","type":"address"}, {"name":"amount","type":"uint64"} ], "outputs": [ ] } ], "data": [ ], "events": [ ]},
                key: '',
            },

            // Use tonos-cli to generate your phrase
            // !!! Never commit it in your repos !!!
            keys: {
                phrase: 'melody clarify hand pause kit economy bind behind grid witness cheap tomorrow',
                amount: 20,
            }
        },
        mainnet: {
            ton_client: {
                // See the TON client specification for all available options
                network: {
                    server_address: 'https://main.ton.dev',
                    endpoints: [
                        'https://main2.ton.dev/',
                        'https://main3.ton.dev/',
                        'https://main4.ton.dev/'
                    ]
                },
            },

            // This giver is default local-node giver
            giver: {
                address: '',
                abi: { "ABI version": 2, "header": ["time", "expire"], "functions": [ { "name": "constructor", "inputs": [ ], "outputs": [ ] }, { "name": "sendGrams", "inputs": [ {"name":"dest","type":"address"}, {"name":"amount","type":"uint64"} ], "outputs": [ ] } ], "data": [ ], "events": [ ]},
                key: '',
            },

            // Use tonos-cli to generate your phrase
            // !!! Never commit it in your repos !!!
            keys: {
                phrase: '',
                amount: 20,
            }
        }
    },
};