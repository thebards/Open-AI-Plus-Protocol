// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';

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
     * @notice Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 hashedMessage,
        string memory name,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) 
        internal 
        view 
    {
        require(sig.deadline >= block.timestamp, 'SignatureExpired');
        bytes32 digest = _calculateDigest(hashedMessage, name);
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress != address(0) && recoveredAddress == expectedAddress, 'SignatureInvalid');
    }

    /**
     * @notice Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator(
        string memory name
    ) 
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
     * @notice Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
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