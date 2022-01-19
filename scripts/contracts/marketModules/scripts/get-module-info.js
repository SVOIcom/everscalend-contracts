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
        console.log(`Module state: ${pp(await module.getModuleState())}`);
        console.log(`Contract code version: ${await module.contractCodeVersion()}`);
        console.log(`Owner address: ${await module.getOwner()}`);
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