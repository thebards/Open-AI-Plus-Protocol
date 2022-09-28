// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';

/**
 * @title BardsPausable
 *
 * @notice This is an abstract contract that implements internal BardsHub state setting and validation.
 *
 * whenNotPaused: Either CurationPaused or Unpaused.
 * whenCurationEnabled: When Unpaused only.
 */
abstract contract BardsPausable {
	DataTypes.ProtocolState private _state;

	// Time last paused for both pauses
    uint256 public lastCurationPauseTime;
    uint256 public lastPauseTime;

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    modifier whenCurationEnabled() {
        _validateCurationEnabled();
        _;
    }

    /**
     * @notice Returns the current protocol state.
     *
     * @return ProtocolState The Protocol state, an enum, where:
     *      0: Unpaused
     *      1: CurationPaused
     *      2: Paused
     */
    function getState() external view returns (DataTypes.ProtocolState) {
        return _state;
    }

    function _setState(DataTypes.ProtocolState newState) internal {
        DataTypes.ProtocolState prevState = _state;
        _state = newState;
		if (newState == DataTypes.ProtocolState.Paused){
			lastPauseTime = block.timestamp;
		}else if (newState == DataTypes.ProtocolState.CurationPaused){
			lastCurationPauseTime = block.timestamp;
		}
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _validateCurationEnabled() internal view {
        if (_state != DataTypes.ProtocolState.Unpaused) {
            revert Errors.CurationPaused();
        }
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.ProtocolState.Paused) revert Errors.Paused();
    }
}