/**
 * Test steps:
 * 1. Load contracts
 * 2. Deploy TestSwapPair contract
 * 3. Deploy TestRequestPrice contract
 * 4. Set test balances in TestSwapPair contract
 * 5. Add two tokens to oracle contract: one left and one right
 * 6. Request prices from testSwapPair contract offchain
 * 7. Request prices from testRequestPriceContract onchain and get results
 * 8. Set price using offchain function
 * 9. Request prices from testSwapPair contract offchain
 * 10. Request prices from testRequestPriceContract onchain and get results
 */

const { Oracle, extendContractToOracle } = require('../modules/oracleWrapper');
const { MsigWallet, extendContractToWallet } = require('../../wallet/modules/walletWrapper');

const { loadContractData } = require('../../../utils/migration');
const { operationFlags } = require('../../../utils/common');
const configuration = require('../../../scripts.conf');
const { loadEssentialContracts } = require('../../../utils/contracts');


async function offchainPrices(oracleContract, firstTokenAddress, secondTokenAddress, testPayload) {
    let firstTokenPrice = await oracleContract.getTokenPrice(firstTokenAddress, testPayload);
    let secondTokenPrice = await oracleContract.getTokenPrice(secondTokenAddress, testPayload);
    return {
        firstTokenPrice,
        secondTokenPrice
    }
}

async function internalPrices(testRequestPriceContract, msigWallet, firstTokenAddress, secondTokenAddress) {
    await testRequestPriceContract.run({
        method: 'requestPrice',
        params: {
            tokenRoot: firstTokenAddress
        },
        keyPair: msigWallet.keyPair
    });

    let firstTokenPrice = await testRequestPriceContract.call({
        method: 'getResults',
        params: {},
        keyPair: msigWallet.keyPair
    });

    await testRequestPriceContract.run({
        method: 'requestPrice',
        params: {
            tokenRoot: secondTokenAddress
        },
        keyPair: msigWallet.keyPair
    });

    let secondTokenPrice = await testRequestPriceContract.call({
        method: 'getResults',
        params: {},
        keyPair: msigWallet.keyPair
    });

    return {
        firstTokenPrice,
        secondTokenPrice
    };
}

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        oracle: true
    })

    // await locklift.giver.deployContract({
    //     contract: testSwapPairContract,
    //     constructorParams: {},
    //     initParams: {},
    //     keyPair: msigWallet.keyPair
    // });

    // await locklift.giver.deployContract({
    //     contract: testRequestPriceContract,
    //     constructorParams: {},
    //     initParams: {},
    //     keyPair: msigWallet.keyPair
    // });

    // // testRequestPriceContract.setAddress('0:09813be34af872782f3d10e4c28f93031113fb0f30995f8faf1fa62444640af2');
    // // testSwapPairContract.setAddress('0:b9f9bad600cc30ae47501d7a4c0671a47116b953b7d70d07fdcc0f0e00ece977');

    // let firstTokenAddress = locklift.utils.zeroAddress;
    // let secondTokenAddress = ''; //locklift.utils.zeroAddress.replace(/0$/, '1')
    // let firstTokenAddPayload = await oracleContract.addToken(firstTokenAddress, testSwapPairContract.address, true);
    // let secondTokenAddPayload = await oracleContract.addToken(secondTokenAddress, testSwapPairContract.address, false);

    // let testBalances = {
    //     left: '1000000',
    //     right: '200000',
    //     minted: '1234567890'
    // };

    // await testSwapPairContract.run({
    //     method: 'setBalances',
    //     params: testBalances,
    //     keyPair: msigWallet.keyPair
    // });

    // await testRequestPriceContract.run({
    //     method: 'setInitialInfo',
    //     params: {
    //         _oracle: oracleContract.address,
    //         payload: firstTokenAddPayload
    //     },
    //     keyPair: msigWallet.keyPair
    // });

    // await msigWallet.transfer(
    //     oracleContract.address,
    //     locklift.utils.convertCrystal(0.5, 'nano'),
    //     operationFlags.FEE_FROM_CONTRACT_BALANCE,
    //     false,
    //     firstTokenAddPayload
    // );

    // await msigWallet.transfer(
    //     oracleContract.address,
    //     locklift.utils.convertCrystal(0.5, 'nano'),
    //     operationFlags.FEE_FROM_CONTRACT_BALANCE,
    //     false,
    //     secondTokenAddPayload
    // );

    // let {
    //     offFirstTokenPrice,
    //     offSecondTokenPrice
    // } = await offchainPrices(oracleContract, firstTokenAddress, secondTokenAddress, firstTokenAddPayload);

    // let {
    //     onFirstTokenPrice,
    //     onSecondTokenPrice
    // } = await internalPrices(testRequestPriceContract, msigWallet, firstTokenAddress, secondTokenAddress);

    // let firstTokenExternalPrice = await oracleContract.externalUpdatePrice(firstTokenAddress, '100', '1');
    let secondTokenExternalPrice = await contracts.oracle.externalUpdatePrice({
        tokenRoot: '0:22851129f9d892ea040d8eac15e0cf1568986f01da45e8bac9538b0e0c9e8ba7', 
        tokens: 10e9, 
        usd: '1'
    });

    // await msigWallet.transfer(
    //     oracleContract.address,
    //     locklift.utils.convertCrystal(0.5, 'nano'),
    //     operationFlags.FEE_FROM_CONTRACT_BALANCE,
    //     false,
    //     firstTokenExternalPrice
    // );

    await contracts.msigWallet.transfer({
        destination: contracts.oracle.address,
        value: contracts.locklift.utils.convertCrystal(0.5, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: secondTokenExternalPrice
    });

    // let {
    //     offFirstTokenPriceUpd,
    //     offSecondTokenPriceUpd
    // } = await offchainPrices(oracleContract, firstTokenAddress, secondTokenAddress, firstTokenAddPayload);

    // let {
    //     onFirstTokenPriceUpd,
    //     onSecondTokenPriceUpd
    // } = await internalPrices(testRequestPriceContract, msigWallet, firstTokenAddress, secondTokenAddress);

    // console.log(await oracleContract.getAllTokenPrices(firstTokenAddPayload));

    // let removeTokenPayload = await oracleContract.removeToken(firstTokenAddress);
    // await msigWallet.transfer(
    //     oracleContract.address,
    //     locklift.utils.convertCrystal(0.5, 'nano'),
    //     operationFlags.FEE_FROM_CONTRACT_BALANCE,
    //     false,
    //     removeTokenPayload
    // );

    // console.log(await oracleContract.getAllTokenPrices(firstTokenAddPayload));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)