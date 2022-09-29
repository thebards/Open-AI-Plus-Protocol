
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {BardsCurationBase} from '../core/curations/BardsCurationBase.sol';
import {MockBardsHubStorage} from './MockBardsHubStorage.sol';
import {VersionedInitializable} from '../upgradeablity/VersionedInitializable.sol';
import {BardsPausable} from '../core/govs/BardsPausable.sol';

/**
 * @notice A mock upgraded bardsHub contract that is used to validate that the initializer cannot be called with the same revision.
 */
contract MockBardsHubWithBadRevision is
    BardsCurationBase,
    VersionedInitializable,
    BardsPausable,
    MockBardsHubStorage
{
    uint256 internal constant REVISION = 1; // Should fail the initializer check

    function initialize(uint256 newValue) 
        external 
        initializer
    {
        _additionalValue = newValue;

    }

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}