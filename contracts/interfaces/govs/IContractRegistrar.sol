// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IContractRegistrar {
	/**
     * @notice Set HUB
     * @param _HUB HUB contract address
     */
	function setHub(address _HUB) external;
	
}