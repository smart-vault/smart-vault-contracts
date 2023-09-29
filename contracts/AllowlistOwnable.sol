// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AllowlistOwnable is Ownable {
    mapping(address => bool) public allowlist;
    bool public allowListEnabled = true;

    event EnabledAllowList();
    event DisableAllowList();
    event UserAllowList(address account, bool isAllowed);

    function isAllowlisted(address addr) public view returns (bool) {
        return allowlist[addr];
    }

    function isOwnerOrInAllowlisted(address addr) public view returns (bool) {
        if(owner() == _msgSender()){ return true;}
        return allowlist[addr];
    }

    modifier onlyAllowList() {
        if (allowListEnabled) {
            if (!isAllowlisted(_msgSender())) {
                revert("AlllowlistOwner: caller is not in the AllowList");
            }
        }
        _;
    }

    modifier onlyOwnerOrInAllowList() {
        if (owner() != _msgSender()){
            if (allowListEnabled) {
                if (!isAllowlisted(_msgSender())) {
                    revert("AlllowlistOwner: caller is not the Owner or in the AllowList");
                }
            }
        }
        _;
    }

    function _addAllowlistAddresses(address[] memory _address) internal virtual {
        require(_address.length > 0, "AlllowlistOwner: Must provide at least one address");
        for(uint256 i=0; i<_address.length; i++){
            _setAllowlistUser(_address[i], true);
        }
    }

    function _setAllowlistUser(address addr, bool _isAllowlisted) internal virtual {
        require(addr != address(0x0), "AlllowlistOwner: Need a valid address");
        allowlist[addr] = _isAllowlisted;
        emit UserAllowList(addr, _isAllowlisted);
    }

    function _enableAllowList() internal virtual {
        allowListEnabled = true;
        emit EnabledAllowList();
    }

    function _disableAllowList() internal virtual {
        allowListEnabled = false;
        emit DisableAllowList();
    }

}