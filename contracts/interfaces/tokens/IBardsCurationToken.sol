// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationToken
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for the BardsCurationToken contract.
 */
interface IBardsCurationToken {
     // -- Mint and Burn --
    function burn(uint256 amount) external;

    /**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @dev Add a new minter.
     * @param _account Address of the minter
     */
    function addMinter(address _account) external;

    /**
     * @dev Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) external;

    /**
     * @dev Renounce to be a minter.
     */
    function renounceMinter() external;

    /**
     * @dev Return if the `_account` is a minter or not.
     * @param _account Address to check
     * @return True if the `_account` is minter
     */
    function isMinter(address _account) external view returns (bool);

    /**
     * @notice Approve token allowance by validating a message signed by the holder.
     *
     * @param _owner The token owern.
     * @param _spender The token spender.
     * @param _value Amount of tokens to approve the spender.
     * @param _sig The EIP712 signature struct.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        DataTypes.EIP712Signature calldata _sig
    ) external;
}