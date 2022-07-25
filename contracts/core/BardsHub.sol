// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../interfaces/curations/IProfileCuration.sol';
import './curations/BardsCurationBase.sol';
import '../interfaces/IBardsHub.sol';


contract BardsHub is BardsCurationBase, IBardsHub {
	uint256 internal _tokenIdCounter;

    function initialize(
        string calldata name,
        string calldata symbol
    ) external override {
        super._initialize(name, symbol);
    }

}