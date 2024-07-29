// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mock
 * @dev Simple ERC20 Token example, with mintable token creation.
 */
contract RewardToken is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of the existing tokens.
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mint new tokens.
     * @param to Address to receive the tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
