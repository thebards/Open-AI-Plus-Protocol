// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {VersionedInitializable} from '../../upgradeablity/VersionedInitializable.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {Errors} from '../../utils/Errors.sol';

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
contract BardsShareToken is
    VersionedInitializable,
    ContractRegistrar,
    ERC20
{
    uint256 internal constant REVISION = 1;

    constructor() ERC20("Bards Share Token", "BST"){}

    function initialize(
        address _HUB
    ) 
        external 
        initializer 
    {   
        if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        ContractRegistrar._initialize(_HUB);
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burnFrom(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

}