pragma ton-solidity 0.47.0;

import { MsgFlag } from '../libraries/MsgFlag.sol';

library RolesErrors {
    uint8 constant CANNOT_UPGRADE = 220;
    uint8 constant CANNOT_CHANGE_PARAMS = 221;
    uint8 constant IS_NOT_OWNER = 222;
    
}

abstract contract IRoles {
    address _owner;
    mapping(address => bool) _canUpgrade;
    mapping(address => bool) _canChangeParams;

    function setUpgrader(address upgrader, bool allowed) external onlyOwner {
        tvm.rawReserve(msg.value, 2);

        _canUpgrade[upgrader] = allowed;

        address(msg.sender).transfer({
            value: 0,
            flag: MsgFlag.REMAINING_GAS
        });
    }

    function setParamChanger(address paramChanger, bool allowed) external onlyOwner {
        tvm.rawReserve(msg.value, 2);

        _canChangeParams[paramChanger] = allowed;

        address(msg.sender).transfer({
            value: 0,
            flag: MsgFlag.REMAINING_GAS
        });
    }

    function changeOwner(address _newOwner) external onlyOwner {
        tvm.rawReserve(msg.value, 2);

        _owner = _newOwner;

        address(msg.sender).transfer({
            value: 0,
            flag: MsgFlag.REMAINING_GAS
        });
    }

    function getOwner() external view returns(address) {
        return _owner;
    }

    function getUpgraders() external view returns(mapping(address => bool)) {
        return _canUpgrade;
    }

    function getParamChangers() external view returns(mapping(address => bool)) {
        return _canChangeParams;
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            RolesErrors.IS_NOT_OWNER
        );
        _;
    }

    modifier canUpgrade() {
        require(
            _canUpgrade[msg.sender] ||
            msg.sender == _owner,
            RolesErrors.CANNOT_UPGRADE
        );
        _;
    }

    modifier canChangeParams() {
        require(
            _canChangeParams[msg.sender] ||
            msg.sender == _owner,
            RolesErrors.CANNOT_CHANGE_PARAMS
        );
        _;
    }
    
}