
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import '../core/curations/BardsCurationBase.sol';
import './MockBardsHubStorage.sol';
import '../upgradeablity/VersionedInitializable.sol';
import '../core/govs/BardsPausable.sol';

/**
 * @notice A mock upgraded BardsHub contract that is used mainly to validate that the initializer works as expected and
 * that the storage layout after an upgrade is valid.
 */
contract MockBardsHub is
    BardsCurationBase,
    VersionedInitializable,
    BardsPausable,
    MockBardsHubStorage
{
    uint256 internal constant REVISION = 2;

    function initialize(uint256 newValue) external initializer {
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