pragma ton-solidity >= 0.43.0;

interface ILockable {
    function unlock(address, TvmCell args) external;
}

abstract contract ACLockable is ILockable {
    bool _lock;
    mapping(address => bool) _userLocks;
    
    function _lockUser(address _user, bool _locked) internal {
        _userLocks[_user] = _locked;
    }

    function _generalLock(bool _locked) internal {
        _lock = _locked;
    }

    function _isLocked() internal returns (bool) {
        return _lock;
    }

    function _isUserLocked(address _user) internal returns (bool) {
        return _userLocks[_user];
    }
}