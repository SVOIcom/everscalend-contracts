pragma ton-solidity >= 0.39.0;

import '../../utils/TIP3/interfaces/IRootTokenContract.sol';

interface ITIP3Deployer {
    function deployTIP3(IRootTokenContract.IRootTokenContractDetails rootInfo, uint128 deployGrams, uint256 pubkeyToInsert, TvmCell payload) external responsible returns(address, TvmCell);

    function getFutureTIP3Address(IRootTokenContract.IRootTokenContractDetails rootInfo, uint256 pubkeyToInsert) external responsible returns(address);
}