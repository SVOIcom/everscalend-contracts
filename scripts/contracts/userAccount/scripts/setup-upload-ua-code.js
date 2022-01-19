const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true,
        user: true
    });

    let codeVersion = (await contracts.userAccountManager.getUserAccountCode({version: 0}) == 'te6ccgEBAQEAAgAAAA==') ?
                        0 : 
                        Number(await contracts.userAccount.contractCodeVersion()) + 1;

    let codeUploadPayload = await contracts.userAccountManager.uploadUserAccountCode({
        code: contracts.userAccount.code,
        version: codeVersion
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        payload: codeUploadPayload
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