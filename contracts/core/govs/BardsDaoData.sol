// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IBardsDaoData} from '../../interfaces/govs/IBardsDaoData.sol';
import {Constants} from '../../utils/Constants.sol';
import {Errors} from '../../utils/Errors.sol';
import {Events} from '../../utils/Events.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {VersionedInitializable} from '../../upgradeablity/VersionedInitializable.sol';

/**
 * @title BardsDaoData
 * @author TheBards Protocol
 *
 * @notice This contract contains simple data relevant to the bards Dao, such as the module governance address, treasury
 * address and protocol fee BPS.
 *
 * NOTE: The reason we have an additional governance address instead of just fetching it from the hub is to
 * allow the flexibility of using different governance executors.
 */
contract BardsDaoData is 
    VersionedInitializable, 
    IBardsDaoData 
{
    address internal _governance;
    uint256 internal constant REVISION = 1;

	/// The Bards protocol fee
	DataTypes.ProtocolFeeSetting internal _protocolFeeSetting;

    modifier onlyGov() {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        _;
    }

/// @inheritdoc IBardsDaoData
    function initialize(
        address governance,
        address treasury,
        uint32 protocolFee,
        uint32 defaultCurationBps,
        uint32 defaultStakingBps
    ) 
        external 
        override 
        initializer
    {
        _setGovernance(governance);
        _setTreasury(treasury);
        _setProtocolFee(protocolFee);
        _setDefaultCurationBps(defaultCurationBps);
        _setDefaultStakingBps(defaultStakingBps);
    }

    /// @inheritdoc IBardsDaoData
    function setGovernance(
        address newGovernance
    ) 
        external 
        override 
        onlyGov 
    {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc IBardsDaoData
    function setTreasury(
        address newTreasury
    ) 
        external 
        override 
        onlyGov 
    {
        _setTreasury(newTreasury);
    }

    /// @inheritdoc IBardsDaoData
    function setProtocolFee(
        uint32 newProtocolFee
    ) 
        external 
        override 
        onlyGov 
    {
        _setProtocolFee(newProtocolFee);
    }

    /// @inheritdoc IBardsDaoData
    function setDefaultCurationBps(
        uint32 newDefaultCurationBps
    ) 
        external 
        override 
        onlyGov 
    {
        _setDefaultCurationBps(newDefaultCurationBps);
    }

    /// @inheritdoc IBardsDaoData
    function setDefaultStakingBps(
        uint32 newDefaultStakingBps
    ) 
        external 
        override 
        onlyGov 
    {
        _setDefaultStakingBps(newDefaultStakingBps);
    }

    /// @inheritdoc IBardsDaoData
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /// @inheritdoc IBardsDaoData
    function getTreasury() external view override returns (address) {
        return _protocolFeeSetting.treasury;
    }

    /// @inheritdoc IBardsDaoData
    function getProtocolFee() external view override returns (uint32) {
        return _protocolFeeSetting.feeBps;
    }

    /// @inheritdoc IBardsDaoData
    function getDefaultCurationBps() external view override returns (uint32) {
        return _protocolFeeSetting.defaultCurationBps;
    }

    /// @inheritdoc IBardsDaoData
    function getDefaultStakingBps() external view override returns (uint32) {
        return _protocolFeeSetting.defaultStakingBps;
    }

    //@inheritdoc IBardsDaoData
    function getProtocolFeePair() external view override returns (address, uint32) {
        return (_protocolFeeSetting.treasury, _protocolFeeSetting.feeBps);
    }

    //@inheritdoc IBardsDaoData
    function getProtocolFeeSetting() external view override returns (DataTypes.ProtocolFeeSetting memory) {
        return _protocolFeeSetting;
    }

    //@inheritdoc IBardsDaoData
    function getFeeAmount(uint256 _amount) external view override returns (uint256) {
        return (_amount * _protocolFeeSetting.feeBps) / Constants.MAX_BPS;
    }

    function _setGovernance(address newGovernance) internal {
        if (newGovernance == address(0)) revert Errors.InitParamsInvalid();
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.ProtocolGovernanceSet(prevGovernance, newGovernance, block.timestamp);
    }

    function _setTreasury(address newTreasury) internal {
        if (newTreasury == address(0)) revert Errors.InitParamsInvalid();
        address prevTreasury = _protocolFeeSetting.treasury;
        _protocolFeeSetting.treasury = newTreasury;
        emit Events.ProtocolTreasurySet(prevTreasury, newTreasury, block.timestamp);
    }

    function _setProtocolFee(uint32 newProtocolFee) internal {
        if (newProtocolFee >= Constants.MAX_BPS / 2) revert Errors.InitParamsInvalid();
        uint32 prevProtocolFee = _protocolFeeSetting.feeBps;
        _protocolFeeSetting.feeBps = newProtocolFee;
        emit Events.ProtocolFeeSet(prevProtocolFee, newProtocolFee, block.timestamp);
    }

    function _setDefaultCurationBps(uint32 newDefaultCurationBps) internal {
        if (newDefaultCurationBps >= Constants.MAX_BPS / 2) revert Errors.InitParamsInvalid();
        uint32 prevDefaultCurationBps = _protocolFeeSetting.defaultCurationBps;
        _protocolFeeSetting.defaultCurationBps = newDefaultCurationBps;
        emit Events.DefaultCurationFeeSet(prevDefaultCurationBps, newDefaultCurationBps, block.timestamp);
    }

    function _setDefaultStakingBps(uint32 newDefaultStakingBps) internal {
        if (newDefaultStakingBps >= Constants.MAX_BPS / 2) revert Errors.InitParamsInvalid();
        uint32 prevDefaultStakingBps = _protocolFeeSetting.defaultStakingBps;
        _protocolFeeSetting.defaultStakingBps = newDefaultStakingBps;
        emit Events.DefaultStakingFeeSet(prevDefaultStakingBps, newDefaultStakingBps, block.timestamp);
    }

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}