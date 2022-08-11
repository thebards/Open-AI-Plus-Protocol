// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/DataTypes.sol';

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
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool);

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