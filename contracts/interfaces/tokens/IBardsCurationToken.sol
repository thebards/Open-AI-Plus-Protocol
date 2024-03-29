// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationToken
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for the BardsCurationToken contract.
 */
interface IBardsCurationToken is IERC20 {
     // -- Mint and Burn --
    function burn(uint256 amount) external;

    /**
     * @notice burn tokens from.
     * @param _from Address to burn tokens
     * @param _amount Amount of tokens to mint
     */
    function burnFrom(address _from, uint256 _amount) external;

    /**
     * @notice Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Add a new minter.
     * @param _account Address of the minter
     */
    function addMinter(address _account) external;

    /**
     * @notice Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) external;

    /**
     * @notice Renounce to be a minter.
     */
    function renounceMinter() external;

    /**
     * @notice Return if the `_account` is a minter or not.
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