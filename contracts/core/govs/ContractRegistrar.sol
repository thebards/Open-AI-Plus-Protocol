// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/govs/IContractRegistrar.sol';
import '../../interfaces/IBardsHub.sol';
import '../../utils/Events.sol';
import '../../interfaces/tokens/IBardsShareToken.sol';
import '../../interfaces/tokens/IBardsCurationToken.sol';
import '../../interfaces/tokens/IBardsStaking.sol';
import '../../interfaces/govs/IRewardsManager.sol';
import '../../interfaces/govs/IEpochManager.sol';
import '../../interfaces/govs/IBardsDaoData.sol';
import '../../interfaces/minters/IProgrammableMinter.sol';
import '../trades/IWETH.sol';

/**
 * @title ContractRegistrar
 * 
 * @author TheBards Protocol
 * 
 * @notice This contract provides an interface to interact with the HUB.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract ContractRegistrar is IContractRegistrar {
	address internal HUB;
    mapping(bytes32 => address) private addressCache;

	modifier onlyHub() {
        require(msg.sender == HUB, "Only HUB can call");
        _;
    }

    modifier onlyGov(){
        require(msg.sender == bardsHub().getGovernance(), 'Only governance can call');
        _;
    }

    /**
     * @notice Initialize the controller.
     */
    function _initialize(address _HUB) internal {
        _setHub(_HUB);
    }

    /// @inheritdoc IContractRegistrar
    function setHub(address _HUB) external override onlyHub {
        _setHub(_HUB);
    }

    /**
     * @notice Set HUB.
     * @param _HUB Controller contract address
     */
    function _setHub(address _HUB) internal {
        require(_HUB != address(0), "HUB must be set");
        HUB = _HUB;
        emit Events.HUBSet(_HUB, block.timestamp);
    }

    /**
     * @notice Return IBardsHub interface.
     * @return IBardsHub contract registered with HUB
     */
    function bardsHub() internal view returns (IBardsHub) {
        return IBardsHub(HUB);
    }

    /**
     * @notice Return IWETH interface.
     * @return IWETH contract registered with HUB
     */
    function iWETH() internal view returns (IWETH) {
        return IWETH(_resolveContract(keccak256("IWETH")));
    }

    /**
     * @notice Return BardsBardsDaoDataStaking interface.
     * @return BardsDaoData contract registered with HUB
     */
    function bardsDataDao() internal view returns (IBardsDaoData) {
        return IBardsDaoData(_resolveContract(keccak256("BardsDaoData")));
    } 

    /**
     * @notice Return BardsStaking interface.
     * @return BardsStaking contract registered with HUB
     */
    function bardsStaking() internal view returns (IBardsStaking) {
        return IBardsStaking(_resolveContract(keccak256("BardsStaking")));
    } 

    /**
     * @notice Return BardsCurationToken interface.
     * @return Bards Curation token contract registered with HUB
     */
    function bardsCurationToken() internal view returns (IBardsCurationToken) {
        return IBardsCurationToken(_resolveContract(keccak256("BardsCurationToken")));
    }

    /**
     * @notice Return RewardsManager interface.
     * 
     * @return Rewards manager contract registered with HUB
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(keccak256("RewardsManager")));
    }

    /**
     * @notice Return EpochManager interface.
     * 
     * @return Epoch manager contract registered with HUB
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(keccak256("EpochManager")));
    }

    /**
     * @notice Return transferMinter as default minter interface.
     * 
     * @return Transfer Minter contract registered with HUB
     */
    function defaultMinter() internal view returns (IProgrammableMinter) {
        return IProgrammableMinter(_resolveContract(keccak256("TransferMinter")));
    }

    /**
     * @notice Resolve a contract address from the cache or the HUB if not found.
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = bardsHub().getContractAddressRegistered(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @notice Cache a contract address from the HUB _registry.
     * @param _name Name of the contract to sync into the cache
     */
    function _syncContract(string memory _name) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        address contractAddress = bardsHub().getContractAddressRegistered(nameHash);
        if (addressCache[nameHash] != contractAddress) {
            addressCache[nameHash] = contractAddress;
            emit Events.ContractSynced(nameHash, contractAddress, block.timestamp);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the HUB _registry.
     * This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a contract change in the
     * HUB to ensure the protocol is using the latest version
     */
    function syncAllContracts() external {
        _syncContract("IWETH");
        _syncContract("BardsDaoData");
        _syncContract("BardsStaking");
        _syncContract("BardsCurationToken");
        _syncContract("RewardsManager");
        _syncContract("EpochManager");
        _syncContract("TransferMinter");
    }
}