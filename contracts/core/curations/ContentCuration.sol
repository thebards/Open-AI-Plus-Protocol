// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../../interfaces/curations/IContentCuration.sol';
import './BardsCurationBase.sol';

/**
 * @title ProfileCuration
 * @author TheBards Protocol
 *
 * @notice This contract is the self curation that presented as a CV or profile NFT 
 * that explains who we are, what we have and what we do.
 */
contract ContentCuration is IContentCuration, BardsCurationBase {
	address public immutable HUB;

	uint256 internal _tokenIdCounter;

    function initialize(
        string calldata name,
        string calldata symbol
    ) external override {
        super._initialize(name, symbol);
    }
}