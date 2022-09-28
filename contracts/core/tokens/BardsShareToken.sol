// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


/**
 * @title BardsShareToken contract
 * @author TheBards Protocol
 * @notice This is the implementation of the Bards Share ERC20 token (BST).
 *
 * BST are created for each curation.
 * The BardsHub contract is the owner of BST tokens and the only one allowed to mint or
 * burn them. BST tokens are transferrable and their holders can do any action allowed
 * in a standard ERC20 token implementation except for burning them.
 *
 * This contract is meant to be used as the implementation for Minimal Proxy clones for
 * gas-saving purposes.
 */
contract BardsShareToken is ERC20Upgradeable{

    function initialize() external initializer {
        ERC20Upgradeable.__ERC20_init("Bards Share Token", "BST");
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burnFrom(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}