// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @dev Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     */
    event CurationBpsUpdated(address tokenContract, uint256 tokenId, uint16 curationBps);

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     */
    event CurationSellersUpdated(address tokenContract, uint256 tokenId, address[] sellers);

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsRecipients The addresses where funds are sent after the trade.
     */
    event CurationSellerFundsRecipientsUpdated(address tokenContract, uint256 tokenId, address[] sellerFundsRecipients);

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellerBpses The fee that is sent to the sellers.
     */
    event CurationSellerBpsesUpdated(address tokenContract, uint256 tokenId, uint16[] sellerBpses);
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     */
    event StakingBpsUpdated(address tokenContract, uint256 tokenId, uint16 stakingBps);

    /**
     * @notice Emitted when an curation is created.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     */
    event AuctionCreated(address indexed tokenContract, uint256 indexed tokenId, DataTypes.CurationData curationData);
}