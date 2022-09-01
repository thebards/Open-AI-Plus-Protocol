// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "../interfaces/tokens/IBardsCurationToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TokenUtils {
    /**
     * @dev Transfer tokens from an address to anther.
     * @param _ierc20 Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     * @param _to Address sending to
     */
    function transfer(
        IERC20 _ierc20,
        address _from,
        uint256 _amount,
        address _to
    ) 
        internal 
    {
        if (_amount > 0) {
            address fromAddress = (_from == address(0))? address(this): _from;
            address toAddress = (_to == address(0))? address(this): _to;
            require(_ierc20.transferFrom(fromAddress, toAddress, _amount), "!transfer");
        }
    }

    /**
     * @dev Pull tokens from an address to this contract.
     * @param _ierc20 Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IERC20 _ierc20,
        address _from,
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            require(_ierc20.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _ierc20 Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IBardsCurationToken _ierc20,
        address _to,
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            require(_ierc20.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _bardsCurationToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(
        IBardsCurationToken _bardsCurationToken, 
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            _bardsCurationToken.burn(_amount);
        }
    }
}