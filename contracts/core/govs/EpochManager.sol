// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import '../storages/EpochManagerStorage.sol';
import {ContractRegistrar} from './ContractRegistrar.sol';
import '../../interfaces/govs/IEpochManager.sol';
import '../../utils/Events.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

/**
 * @title EpochManager
 * @notice Produce epochs based on a number of blocks to coordinate contracts in the protocol.
 */
contract EpochManager is EpochManagerStorage, ContractRegistrar, IEpochManager {
	using SafeMath for uint256;

	/**
     * @notice Initialize this contract.
     */
    constructor(address _HUB, uint256 _epochLength) {
        require(_epochLength > 0, "Epoch length cannot be 0");

        ContractRegistrar._initialize(_HUB);

        // NOTE: We make the first epoch to be one instead of zero to avoid any issue
        // with composing contracts that may use zero as an empty value
        lastLengthUpdateEpoch = 1;
        lastLengthUpdateBlock = blockNum();
        epochLength = _epochLength;

        emit Events.EpochLengthUpdate(
            lastLengthUpdateEpoch, 
            epochLength, 
            block.timestamp
        );
    }

    /**
     * @notice Set the epoch length.
     * @notice Set epoch length to `_epochLength` blocks
     * @param _epochLength Epoch length in blocks
     */
    function setEpochLength(
        uint256 _epochLength
    ) 
        external 
        override 
        onlyGov 
    {
        require(_epochLength > 0, "Epoch length cannot be 0");
        require(_epochLength != epochLength, "Epoch length must be different to current");

        lastLengthUpdateEpoch = currentEpoch();
        lastLengthUpdateBlock = currentEpochBlock();
        epochLength = _epochLength;

        emit Events.EpochLengthUpdate(
            lastLengthUpdateEpoch, 
            epochLength, 
            block.timestamp
        );
    }

    /**
     * @notice Run a new epoch, should be called once at the start of any epoch.
     * @notice Perform state changes for the current epoch
     */
    function runEpoch() 
        external 
        override 
    {
        // Check if already called for the current epoch
        require(!isCurrentEpochRun(), "Current epoch already run");

        lastRunEpoch = currentEpoch();

        // Hook for protocol general state updates
        rewardsManager().onUpdateIssuanceRate();

        emit Events.EpochRun(lastRunEpoch, msg.sender, block.timestamp);
    }

    /**
     * @notice Return true if the current epoch has already run.
     * @return Return true if current epoch is the last epoch that has run
     */
    function isCurrentEpochRun() public view override returns (bool) {
        return lastRunEpoch == currentEpoch();
    }

    /**
     * @notice Return current block number.
     * @return Block number
     */
    function blockNum() public view override returns (uint256) {
        return block.number;
    }

    /**
     * @notice Return blockhash for a block.
     * @return BlockHash for `_block` number
     */
    function blockHash(uint256 _block) external view override returns (bytes32) {
        uint256 currentBlock = blockNum();

        require(_block < currentBlock, "Can only retrieve past block hashes");
        require(
            currentBlock < 256 || _block >= currentBlock - 256,
            "Can only retrieve hashes for last 256 blocks"
        );

        return blockhash(_block);
    }

    /**
     * @notice Return the current epoch, it may have not been run yet.
     * @return The current epoch based on epoch length
     */
    function currentEpoch() public view override returns (uint256) {
        return lastLengthUpdateEpoch.add(epochsSinceUpdate());
    }

    /**
     * @notice Return block where the current epoch started.
     * @return The block number when the current epoch started
     */
    function currentEpochBlock() public view override returns (uint256) {
        return lastLengthUpdateBlock.add(epochsSinceUpdate().mul(epochLength));
    }

    /**
     * @notice Return the number of blocks that passed since current epoch started.
     * @return Blocks that passed since start of epoch
     */
    function currentEpochBlockSinceStart() external view override returns (uint256) {
        return blockNum() - currentEpochBlock();
    }

    /**
     * @notice Return the number of epoch that passed since another epoch.
     * @param _epoch Epoch to use as since epoch value
     * @return Number of epochs and current epoch
     */
    function epochsSince(uint256 _epoch) external view override returns (uint256) {
        uint256 epoch = currentEpoch();
        return _epoch < epoch ? epoch.sub(_epoch) : 0;
    }

    /**
     * @notice Return number of epochs passed since last epoch length update.
     * @return The number of epoch that passed since last epoch length update
     */
    function epochsSinceUpdate() public view override returns (uint256) {
        return blockNum().sub(lastLengthUpdateBlock).div(epochLength);
    }
}