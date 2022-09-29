// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsDaoData
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsDaoData contract, 
 * which allows an optional fee percentage, recipient governancor to be set for TheBards protocol Dao.
 */
interface IBardsDaoData {
    /**
     * @notice Sets the governance address. This function can only be called by governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the treasury address. This function can only be called by governance.
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the protocol fee. This function can only be called by governance.
     *
     * @param newProtocolFee The new treasury fee to set.
     */
    function setProtocolFee(uint32 newProtocolFee) external;

    /**
     * @notice Sets the Default Curation Bps. This function can only be called by governance.
     *
     * @param newDefaultCurationBps The new default curation Bps to set.
     */
    function setDefaultCurationBps(uint32 newDefaultCurationBps) external;

    /**
     * @notice Sets the default staking Bps. This function can only be called by governance.
     *
     * @param newDefaultStakingBps The new default staking Bps to set.
     */
    function setDefaultStakingBps(uint32 newDefaultStakingBps) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the protocol fee bps.
     *
     * @return uint32 The protocol fee bps.
     */
    function getProtocolFee() external view returns (uint32);

    /**
     * @notice Returns the default curation fee bps.
     *
     * @return uint32 The default curation fee bps.
     */
    function getDefaultCurationBps() external view returns (uint32);

    /**
     * @notice Returns the default staking fee bps.
     *
     * @return uint32 The default staking fee bps.
     */
    function getDefaultStakingBps() external view returns (uint32);

    /**
     * @notice Returns the protocol fee setting in a single call.
     *
     * @return ProtocolFeeSetting The DataType contains the treasury address and the protocol fee.
     */
    function getProtocolFeeSetting() external view returns (DataTypes.ProtocolFeeSetting memory);

    /**
     * @notice Returns the treasury address and protocol fee in a single call.
     *
     * @return tuple First, the treasury address, second, the protocol fee.
     */
    function getProtocolFeePair() external view returns (address, uint32);

    /**
     * @notice Computes the fee for a given uint256 amount
     * @param _amount The amount to compute the fee for
     * @return The amount to be paid out to the fee recipient
     */
    function getFeeAmount(uint256 _amount) external view returns (uint256);
}