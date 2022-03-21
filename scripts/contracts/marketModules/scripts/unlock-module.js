const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        marketModules: true,
        wallet: true
    });

    /**
     * @type {Module}
     */
    let module = contracts.modules.liquidation;
    let payload = await module.ownerUserUnlock({
        _user: '0:7028282fa0363d7e58fa1917071aa723931f033e4e421e15bde636ef570d1255',
        _locked: false
    });

    // let payload = await module.ow

    await contracts.msigWallet.transfer({
        destination: module.address,
        value: convertCrystal(0.3, 'nano'),
        payload
    });
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)