const { convertCrystal } = require("locklift/locklift/utils");
const configuration = require("../../../scripts.conf");
const { writeContractData } = require("../../../utils/migration/_manageContractData");
const { operationFlags } = require("../../../utils/common/_transferFlags");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    let payloadToDeploy = await contracts.userAccountManager.createUserAccount({
        tonWallet: contracts.msigWallet.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(3, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: payloadToDeploy
    });

    let userAccountContract = await contracts.locklift.factory.getContract('UserAccount', configuration.buildDirectory);
    let userAccountAddress = await contracts.userAccountManager.calculateUserAccoutAddress({
        tonWallet: contracts.msigWallet.address
    });
    userAccountContract.setAddress(userAccountAddress);
    userAccountContract.setKeyPair(contracts.msigWallet.keyPair);

    let filename = writeContractData(userAccountContract, userAccountContract.name);
    console.log(`Contract data is written to ${filename}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)