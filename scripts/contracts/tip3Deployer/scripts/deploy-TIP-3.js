const configuration = require("../../scripts.conf");
const initializeLocklift = require("../../utils/initializeLocklift");
const { operationCosts } = require('../modules/tip3DeployerConstants');

const { loadContractData } = require("../../utils/migration/manageContractData");
const { TIP3Deployer, extendContractToTIP3Deployer } = require('../modules/tip3DeployerWrapper');
const { MsigWallet, extendContractToWallet } = require("../../wallet/modules/walletWrapper");
const { operationFlags } = require("../../utils/transferFlags");
const { stringToBytesArray } = require("../../utils/utils");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {TIP3Deployer}
     */
    let tip3DeployerContract = await loadContractData(locklift, `${configuration.network}_TIP3DeployerContract.json`);
    tip3DeployerContract = extendContractToTIP3Deployer(tip3DeployerContract);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = await loadContractData(locklift, `${configuration.network}_MsigWallet.json`);
    msigWallet = extendContractToWallet(msigWallet);

    const tip3RootInfo = {
        name: stringToBytesArray('test'),
        symbol: stringToBytesArray('t'),
        decimals: 9,
        root_public_key: '0x0',
        root_owner_address: msigWallet.address,
        total_supply: 0
    }

    let futureTIP3Address = await tip3DeployerContract.getFutureTIP3Address(tip3RootInfo, '0x' + msigWallet.keyPair.public);
    console.log(`Future TIP-3 address: ${futureTIP3Address}`);

    let tip3DeployPayload = await tip3DeployerContract.deployTIP3(
        tip3RootInfo,
        locklift.utils.convertCrystal(operationCosts.sendToTIP3, 'nano'),
        '0x' + msigWallet.keyPair.public
    );
    await msigWallet.transfer(
        tip3DeployerContract.address,
        locklift.utils.convertCrystal(operationCosts.deployTIP3, 'nano'),
        operationFlags.FEE_FROM_CONTRACT_BALANCE,
        false,
        tip3DeployPayload
    );

    console.log(`TIP-3 root contract deployed at address: ${futureTIP3Address}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)