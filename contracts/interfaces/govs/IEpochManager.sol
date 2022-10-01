// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IEpochManager {

    /**
     * @notice Initialize contract
     *
     * @param _HUB The address of HUB
     * @param _epochLength The epoch length
     */
    function initialize(
        address _HUB, 
        uint256 _epochLength
    ) external;

	// -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}