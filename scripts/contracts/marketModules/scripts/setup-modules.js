const { convertCrystal } = require("locklift/locklift/utils");
const { operationFlags } = require("../../../utils/common/_transferFlags");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        userAM: true,
        marketModules: true
    });

    
    for (let moduleType in contracts.modules) {
        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleType];
        let marketPayload = await module.setMarketAdress({
            _marketAddress: contracts.marketsAggregator.address
        });
        let userAccountManagerPayload = await module.setUserAccountManager({
            _userAccountManager: contracts.userAccountManager.address
        });
        await contracts.msigWallet.transfer({
            destination: module.address,
            value: convertCrystal(1, 'nano'),
            flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
            bounce: false,
            payload: marketPayload
        });
        
        await contracts.msigWallet.transfer({
            destination: module.address,
            value: convertCrystal(1, 'nano'),
            flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
            bounce: false,
            payload: userAccountManagerPayload
        });

        console.log(`${moduleType} module is set up`);
    }

    console.log('Addresses for modules set up');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)