// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IContractRegistrar {
	/**
     * @notice Set Controller. Only callable by current controller.
     * @param _HUB Controller contract address
     */
	function setHub(address _HUB) external;
	
}