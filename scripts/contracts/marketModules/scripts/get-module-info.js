const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true, 
        market: true,
        userAM: true,
        marketModules: true
    });

    for (let moduleName in contracts.modules) {
        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleName];
        console.log(`Module: ${moduleName}`);
        console.log(`Known contract addresses: ${pp(await module.getContractAddresses())}`);
        // console.log(`Module state: ${pp(await module.getModuleState())}`);
        console.log(`Module lock: ${await module.getGeneralLock()}`);
        console.log(`User lock: ${await module.userLock({user: '0:7028282fa0363d7e58fa1917071aa723931f033e4e421e15bde636ef570d1255'})}`);
        console.log(`Contract code version: ${await module.contractCodeVersion()}`);
        console.log(`Owner address: ${await module.getOwner()}`);
        console.log(`ActionId: ${await module.sendActionId()}`);
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