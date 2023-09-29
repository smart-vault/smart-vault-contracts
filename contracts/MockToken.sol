// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    address public owner;

    constructor() ERC20("Mock Token", "MT") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "MockToken: Only owner can mint");
        _mint(to, amount);
    }
}