// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title MyNFT
 * @dev Simple ERC721 Token example, where tokens can be minted by the contract owner.
 */
contract StakingNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    /**
     * @dev Constructor that gives msg.sender the contract ownership and initializes the ERC721 token.
     */
    constructor(string memory name , string memory symbol) Ownable(msg.sender) ERC721(name, symbol) {}

    /**
     * @notice Mints a new token.
     * @param to The address that will own the minted token.
     */
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter);
        _tokenIdCounter++;
    }
}
