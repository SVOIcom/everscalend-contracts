const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    console.log(`Owner: ${await contracts.userAccountManager.getOwner()}`);

    console.log(`Market address: ${await contracts.userAccountManager.marketAddress()}`);

    console.log(`Modules: ${pp(await contracts.userAccountManager.modules())}`);

    console.log(`Existing modules: ${pp(await contracts.userAccountManager.existingModules())}`);

    console.log(`Zero version code exists: ${pp(await contracts.userAccountManager.getUserAccountCode({version: 0}) != 'te6ccgEBAQEAAgAAAA==')}`);

    console.log(`Contract code version: ${await contracts.userAccountManager.contractCodeVersion()}`);

    console.log(`Contract codes available: ${pp(await contracts.userAccountManager.userAccountCodes())}`);

    console.log(`User account address: ${await contracts.userAccountManager.calculateUserAccoutAddress({tonWallet: '0:b7a39c988506b20c37489d58fa20d71dda5bfc6d48bb4a38ad7d47ebf0ba3ad5'})}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)