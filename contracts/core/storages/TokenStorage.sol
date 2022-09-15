// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';
import "hardhat/console.sol";


/**
 * @title TokenStorage
 * 
 * @author TheBards Protocol
 * 
 * @notice Storages and functions for ERC20 and ERC721 token contract.
 */
abstract contract TokenStorage {
	bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant DOMAIN_SALT =
        0x51f3d585afe6dfeb2af01bba0889a36c1db03beec88c6a4d0c53817069026afa; // Randomly generated salt
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)'
        );

    mapping(address => uint256) public sigNonces;

	    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) 
        internal 
        view 
    {
        console.log("deadline: %s, now: %s", sig.deadline, block.timestamp);
        if (sig.deadline < block.timestamp){
            console.log(expectedAddress);
            revert Errors.SignatureExpired();
        }

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert Errors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator(string memory name) 
        internal 
        view 
        returns (bytes32) 
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this),
                    DOMAIN_SALT
                )
            );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
	 * @param name The name of token.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest
     */
    function _calculateDigest(
        bytes32 hashedMessage, 
        string memory name
    ) 
        internal 
        view 
        returns (bytes32) 
    {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(name), hashedMessage)
            );
        }
        return digest;
    }
}