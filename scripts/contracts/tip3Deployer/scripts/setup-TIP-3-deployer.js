const { loadEssentialContracts } = require("../../../utils/contracts");
const Contract = require("locklift/locklift/contract");
const configuration = require("../../../scripts.conf");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true, deployer: true});

    /**
     * @type {Contract}
     */
    let rootTIP3Contract = await contracts.locklift.factory.getContract('RootTokenContract', configuration.buildDirectory);
    /**
     * @type {Contract}
     */
    let walletTIP3Contract = await contracts.locklift.factory.getContract('TONTokenWallet', configuration.buildDirectory);

    let setTIP3RootCodePayload = await contracts.tip3Deployer.setTIP3RootContractCode({_rootContractCode: rootTIP3Contract.code});
    let setTIP3WalletCodePayload = await contracts.tip3Deployer.setTIP3WalletContractCode({_walletContractCode: walletTIP3Contract.code});

    await contracts.msigWallet.transfer({
        destination: contracts.tip3Deployer.address,
        payload: setTIP3RootCodePayload
    });

    await contracts.msigWallet.transfer({
        destination: contracts.tip3Deployer.address,
        payload: setTIP3WalletCodePayload
    });

    let result = await contracts.tip3Deployer.getServiceInfo();

    console.log(`Root contract code is correct: ${result.rootCode == rootTIP3Contract.code}`);
    console.log(`Wallet contract code is correct: ${result.walletCode == walletTIP3Contract.code}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)