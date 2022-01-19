const { convertCrystal } = require("locklift/locklift/utils");
const { operationFlags } = require("../../../utils/common/_transferFlags");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        oracle: true,
        userAM: true,
        walletC: true,
        marketModules: true
    });

    /**
     * @type {String[]}
     */
    let payloads = [];
    payloads.push(await contracts.marketsAggregator.setOracleAddress({
        _oracle: contracts.oracle.address
    }));

    payloads.push(await contracts.marketsAggregator.setUserAccountManager({
        _userAccountManager: contracts.userAccountManager.address
    }));

    payloads.push(await contracts.marketsAggregator.setWalletController({
        _tip3WalletController: contracts.walletController.address
    }));

    let i = 1;
    for (let payload of payloads) {
        await contracts.msigWallet.transfer({
            destination: contracts.marketsAggregator.address,
            payload
        });
        console.log(`${i} message sent`);
        i++;
    }

    console.log(`MarketsAggregator service address setup finished`);

    for (let moduleName in contracts.modules) {
        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleName];

        let operationId = await module.sendActionId();

        let modulePayload = await contracts.marketsAggregator.addModule({
            operationId: Number(operationId),
            module: module.address
        });

        await contracts.msigWallet.transfer({
            destination: contracts.marketsAggregator.address,
            value: convertCrystal(2, 'nano'),
            bounce: false,
            payload: modulePayload
        });
        console.log(`${moduleName} module set up`);
    }

    console.log('Modules for markets are set up');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)