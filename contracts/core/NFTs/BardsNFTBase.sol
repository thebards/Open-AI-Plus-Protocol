// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IBardsNFTBase} from '../../interfaces/NFTs/IBardsNFTBase.sol';
import {Errors} from '../../utils/Errors.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Events} from '../../utils/Events.sol';
import './ERC721Enumerable.sol';
import {TokenStorage} from '../storages/TokenStorage.sol';


/**
 * @title BardsNFTBase
 * @author Lens Protocol
 *
 * @notice This is an abstract base contract to be inherited by other Lens Protocol NFTs, it includes
 * the slightly modified ERC721Enumerable-- which adds an
 * internal operator approval setter, stores the mint timestamp for each token, and replaces the
 * constructor with an initializer.
 */
abstract contract BardsNFTBase is ERC721Enumerable, IBardsNFTBase, TokenStorage {
    bytes32 private constant PERMIT_TYPEHASH = 
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 private constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256(
            'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
        );
    bytes32 private constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');

    // uint256 internal _counter;

    /**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(string calldata name, string calldata symbol) internal {
        ERC721Time.__ERC721_Init(name, symbol);
        emit Events.BaseInitialized(name, symbol, block.timestamp);
    }

    /// @inheritdoc IBardsNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _approve(spender, tokenId);
    }

    /// @inheritdoc IBardsNFTBase
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (operator == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        PERMIT_FOR_ALL_TYPEHASH,
                        owner,
                        operator,
                        approved,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _setOperatorApproval(owner, operator, approved);
    }

    /// @inheritdoc IBardsNFTBase
    // function getDomainSeparator() external view override returns (bytes32) {
    //     return _calculateDomainSeparator(name());
    // }

    /// @inheritdoc IBardsNFTBase
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /// @inheritdoc IBardsNFTBase
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        virtual
        override
    {
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        BURN_WITH_SIG_TYPEHASH,
                        tokenId,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _burn(tokenId);
    }


}