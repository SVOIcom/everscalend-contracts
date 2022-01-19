const { MarketsAggregator } = require("../../contracts/marketAggregator/modules/marketsAggregatorWrapper");
const { Oracle } = require("../../contracts/oracle/modules/oracleWrapper");
const configuration = require("../../scripts.conf");
const { UserAccountManager } = require("../../contracts/userAccount/modules/userAccountManagerWrapper");
const { UserAccount } = require("../../contracts/userAccount/modules/userAccountWrapper");
const { MsigWallet } = require("../../contracts/wallet/modules/walletWrapper");
const initializeLocklift = require("../initializeLocklift");
const { loadContractData } = require("../migration/_manageContractData");
const { Locklift } = require('locklift/locklift');
const { WalletController } = require("../../contracts/walletController/modules/walletControllerWrapper");
const { Module } = require("../../contracts/marketModules/modules/moduleWrapper");
const { TIP3Deployer } = require("../../contracts/tip3Deployer/modules/tip3DeployerWrapper");
const { encodeMessageBody } = require("../common");
const Contract = require("locklift/locklift/contract");

/**
 * @typedef {Object} Modules
 * @property {Module} supply
 * @property {Module} withdraw
 * @property {Module} borrow
 * @property {Module} repay
 * @property {Module} liquidation
 */

/**
 * @typedef {Object} EssentialContracts
 * @property {Locklift} locklift
 * @property {MsigWallet} msigWallet
 * @property {MarketsAggregator} marketsAggregator
 * @property {Oracle} oracle
 * @property {UserAccountManager} userAccountManager
 * @property {UserAccount} userAccount
 * @property {WalletController} walletController
 * @property {Modules} modules
 * @property {TIP3Deployer} tip3Deployer
 * @property {Contract} testSwapPair
 */

/**
 * 
 * @param {Object} p
 * @param {Boolean} p.wallet
 * @param {Boolean} p.market
 * @param {Boolean} p.oracle
 * @param {Boolean} p.userAM
 * @param {Boolean} p.user
 * @param {Boolean} p.walletC
 * @param {Boolean} p.marketModules
 * @param {Boolean} p.deployer
 * @param {Boolean} p.testSP
 * @returns {Promise<EssentialContracts>}
 */
 async function loadEssentialContracts({
        wallet = false, 
        market = false, 
        oracle = false, 
        userAM = false, 
        user = false, 
        walletC = false, 
        marketModules = false, 
        deployer = false,
        testSP = false
    }) {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = undefined;
    if (wallet) {
        msigWallet = new MsigWallet(await loadContractData(locklift, 'MsigWallet'));
    }

    /**
     * @type {MarketsAggregator}
     */
    let marketsAggregator = undefined;
    if (market) {
        marketsAggregator = new MarketsAggregator(await loadContractData(locklift, 'MarketsAggregator'));
    }

    /**
     * @type {Oracle}
     */
    let oracleContract = undefined;
    if (oracle) {
        oracleContract = new Oracle(await loadContractData(locklift, 'Oracle'));
    }

    /**
     * @type {UserAccountManager}
     */
    let userAccountManager = undefined;
    if (userAM) {
        userAccountManager = new UserAccountManager(await loadContractData(locklift, 'UserAccountManager'));
    }

    /**
     * @type {UserAccount}
     */
    let userAccount = undefined;
    if (user) {
        userAccount = new UserAccount(await loadContractData(locklift, 'UserAccount'));
    }

    /**
     * @type {WalletController}
     */
    let walletController = undefined;
    if (walletC) {
        walletController = new WalletController(await loadContractData(locklift, 'WalletController'));
    }

    /**
     * @type {Modules}
     */
    let modules = {};
    if (marketModules) {
        modules.supply = new Module(await loadContractData(locklift, 'SupplyModule'));
        modules.withdraw = new Module(await loadContractData(locklift, 'WithdrawModule'));
        modules.borrow = new Module(await loadContractData(locklift, 'BorrowModule'));
        modules.repay = new Module(await loadContractData(locklift, 'RepayModule'));
        modules.liquidation = new Module(await loadContractData(locklift, 'LiquidationModule'));
    }

    /**
     * @type {TIP3Deployer}
     */
    let tip3Deployer = {};
    if (deployer) {
        tip3Deployer = new TIP3Deployer(await loadContractData(locklift, 'TIP3Deployer'));
    }

    /**
     * @type {Contract}
     */
    let testSwapPair = {};
    if (testSP) {
        testSwapPair = await loadContractData(locklift, 'TestSwapPair');
    }

    return {
        locklift,
        msigWallet,
        marketsAggregator,
        oracle: oracleContract,
        userAccountManager,
        userAccount,
        walletController,
        modules,
        tip3Deployer,
        testSwapPair
    }
}

module.exports = {
    loadEssentialContracts
}