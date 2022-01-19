const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');

const tryToExtractAddress = require('../../../errorHandler/errorHandler');
const { writeContractData } = require('../../../utils/migration/_manageContractData');

const initializeLocklift = require('../../../utils/initializeLocklift');
const configuration = require('../../../scripts.conf');
const { convertCrystal } = require('locklift/locklift/utils');

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    let walletContract = await locklift.factory.getContract('SafeMultisigWallet', configuration.buildDirectory);

    let [keyPair] = await locklift.keys.getKeyPairs();
    walletContract.setKeyPair(keyPair);

    try {
        await locklift.giver.deployContract({
            contract: walletContract,
            constructorParams: {
                owners: ['0x' + walletContract.keyPair.public],
                reqConfirms: 1
            },
            initParams: {},
            keyPair: walletContract.keyPair
        });

        if (walletContract.address) {
            console.log(`Multisig wallet deployed at address: ${walletContract.address}`);
        }

        if (configuration.network == 'local') {
            await locklift.giver.giver.run({
                method: 'sendGrams',
                params: {
                    dest: walletContract.address,
                    amount: convertCrystal(1111111, 'nano')
                }
            });
        }
    } catch (err) {
        console.log(err);
        let address = tryToExtractAddress(err);
        if (address) {
            walletContract.setAddress(address);
            console.log(`Multisig wallet already deployed at address ${walletContract.address}`);
        }
    }

    if (walletContract.address) {
        await writeContractData(walletContract, 'MsigWallet');
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