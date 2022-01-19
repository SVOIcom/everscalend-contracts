pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ITIP3Deployer.sol';
import './interfaces/ITIP3DeployerManageCode.sol';
import './interfaces/ITIP3DeployerServiceInfo.sol';

import './libraries/TIP3DeployerErrorCodes.sol';

import '../utils/libraries/MsgFlag.sol';

import '../utils/interfaces/IUpgradableContract.sol';
import '../utils/TIP3/RootTokenContract.sol';

contract TIP3TokenDeployer is ITIP3Deployer, ITIP3DeployerManageCode, ITIP3DeployerServiceInfo, IUpgradableContract {
    TvmCell rootContractCode;
    TvmCell walletContractCode;
    address ownerAddress;

    uint32 contractCodeVersion;

    /*********************************************************************************************************/
    // Basic functions for deploy and upgrade

    // Contract is deployed using platform
    constructor(address _owner) public {
        tvm.accept();
        ownerAddress = _owner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyOwner {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            ownerAddress,
            rootContractCode,
            walletContractCode,
            updateParams,
            codeVersion
        );
    }

    function onCodeUpgrade(
        address,
        TvmCell,
        TvmCell,
        TvmCell,
        uint32
    ) private {

    }

    /*********************************************************************************************************/
    // Functions for TIP-3 token deploy
    /**
     * @param rootInfo Information required to create TIP-3 token
     * @param deployGrams Amount of tons to transfer to root contract
     * @param pubkeyToInsert Pubker used for contract
     * @param payloadToReturn Payload to return with address of new TIP-3 token (can contain some useful information)
     */
    function deployTIP3(IRootTokenContract.IRootTokenContractDetails rootInfo, uint128 deployGrams, uint256 pubkeyToInsert, TvmCell payloadToReturn) 
        external
        responsible
        override
        checkMsgValue(deployGrams)
        returns (address, TvmCell) 
    {
        tvm.rawReserve(msg.value, 2);
        address tip3TokenAddress = new RootTokenContract{
            value: deployGrams,
            flag: 0,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        }(rootInfo.root_public_key, rootInfo.root_owner_address);

        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (tip3TokenAddress, payloadToReturn);
    }

    /**
     * @param rootInfo Information required to create TIP-3 token
     * @param pubkeyToInsert Pubkey used for contract
     */
    function getFutureTIP3Address(IRootTokenContract.IRootTokenContractDetails rootInfo, uint256 pubkeyToInsert) external override responsible returns (address) {
        tvm.accept();
        TvmCell stateInit = tvm.buildStateInit({
            contr: RootTokenContract,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        });

        return address.makeAddrStd(0, tvm.hash(stateInit));
    }

    /*********************************************************************************************************/
    // TIP-3 code update functions
    /**
     * @param _rootContractCode Code of RootTokenContract
     */
    function setTIP3RootContractCode(TvmCell _rootContractCode) external override onlyOwner {
        tvm.accept();
        rootContractCode = _rootContractCode;
    }

    /**
     * @param _walletContractCode Code of TONTokenWallet
     */
    function setTIP3WalletContractCode(TvmCell _walletContractCode) external override onlyOwner {
        tvm.accept();
        walletContractCode = _walletContractCode;
    }

    function getServiceInfo() external override responsible view returns (ServiceInfo) {
        return ServiceInfo(rootContractCode, walletContractCode);
    }

    /*********************************************************************************************************/
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, TIP3DeployerErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWNER);
        _;
    }

    /**
     * @param gramsRequired Amount of grams required for deploy
     */
    modifier checkMsgValue(uint128 gramsRequired) {
        require(msg.value > gramsRequired, TIP3DeployerErrorCodes.ERROR_MSG_VALUE_IS_TOO_LOW);
        _;
    }
}