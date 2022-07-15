// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     */
    event CurationBpsUpdated(uint256 tokenId, uint16 curationBps);

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     */
    event StakingBpsUpdated(uint256 tokenId, uint16 stakingBps);
}