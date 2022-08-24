// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "../interfaces/tokens/IBardsCurationToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _bardsCurationToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IBardsCurationToken _bardsCurationToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_bardsCurationToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _bardsCurationToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IBardsCurationToken _bardsCurationToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_bardsCurationToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _bardsCurationToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IBardsCurationToken _bardsCurationToken, uint256 _amount) internal {
        if (_amount > 0) {
            _bardsCurationToken.burn(_amount);
        }
    }
}