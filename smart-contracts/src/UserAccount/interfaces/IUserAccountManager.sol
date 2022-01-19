pragma ton-solidity >= 0.39.0;

import { IRoles } from '../../utils/interfaces/IRoles.sol';

interface IUserAccountManager {
    function createUserAccount(address tonWallet) external view;
    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address);

    function uploadUserAccountCode(uint32 version, TvmCell code) external;
    function updateUserAccount(address tonWallet) external;
    function getUserAccountCode(uint32 version) external view responsible returns(TvmCell);
}