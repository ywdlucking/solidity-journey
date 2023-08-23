// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token1 is ERC20 {

    constructor(uint256 initialSupply) ERC20("TOKEN1", "T1"){
        _mint(msg.sender, initialSupply);
    }
}