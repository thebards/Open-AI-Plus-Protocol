// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRoyaltyEngineV1} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IWETH} from "./IWETH.sol";
import {Events} from '../../utils/Events.sol';
import {Errors} from '../../utils/Errors.sol';
import '../../utils/TokenUtils.sol';
import '../BardsHub.sol';
import '../govs/ContractRegistrar.sol';
import '../../interfaces/tokens/IBardsStaking.sol';

/**
 * @title MarketModuleBase
 * @author TheBards Protocol
 * @notice This contract extension supports paying out funds to an external recipient
 */
abstract contract MarketModuleBase is ContractRegistrar {
    using SafeERC20 for IERC20;

    IWETH internal weth;
    // The Manifold Royalty Engine
    IRoyaltyEngineV1 internal royaltyEngine;
    // The address of staking tokens.
    address internal stakingAddress;

    function _initialize(
        address _hub, 
        address _royaltyEngine
    ) internal {
        if (_hub == address(0) || _royaltyEngine == address(0)) revert Errors.InitParamsInvalid();
        ContractRegistrar._initialize(_hub);

        weth = iWETH();
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        stakingAddress = bardsStaking().getStakingAddress();
        
        emit Events.MarketModuleBaseInitialized(
            stakingAddress,
			_royaltyEngine,
			block.timestamp
		);
    }

    /**
     * @notice Update the address of the Royalty Engine, in case of unexpected update on Manifold's Proxy
     * emergency use only – requires a frozen RoyaltyEngineV1 at commit 4ae77a73a8a73a79d628352d206fadae7f8e0f74
     * to be deployed elsewhere, or a contract matching that ABI
     * @param _royaltyEngine The address for the new royalty engine
     */
    function setRoyaltyEngineAddress(
        address _royaltyEngine
    ) 
        public 
        onlyGov 
    {
        require(
            ERC165Checker.supportsInterface(_royaltyEngine, type(IRoyaltyEngineV1).interfaceId),
            "setRoyaltyEngineAddress must match IRoyaltyEngineV1 interface"
        );
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    function isCurrencyWhitelisted(address currency)
		internal 
		view 
		returns (bool) {
        	return bardsHub().isCurrencyWhitelisted(currency);
    }

    function getProtocolFeeSetting()
		internal 
		view 
		returns (DataTypes.ProtocolFeeSetting memory) {
        	return bardsDataDao().getProtocolFeeSetting();
    }

	function getProtocolFee()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getProtocolFee();
	}

	function getDefaultCurationBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultCurationBps();
	}

	function getDefaultStakingBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultStakingBps();
	}

	function getTreasury()
		internal
		view
		returns (address){
			return bardsDataDao().getTreasury();
		}

	function getFeeAmount(uint256 _amount)
		internal
		view
		returns (uint256) {
			return bardsDataDao().getFeeAmount(_amount);
		}

    /**
     * 
     * @notice Pays out the protocol fee to its protocol treasury
     * @param _amount The sale amount
     * @param _payoutCurrency The currency to pay the fee
     * @param _protocolFee The protocol fee
     * @param _protocolTreasury The protocol fee recipient
     * @return The remaining funds after paying the protocol fee
     */
    function _handleProtocolFeePayout(
        uint256 _amount, 
        address _payoutCurrency,
        uint256 _protocolFee,
        address _protocolTreasury
    ) internal returns (uint256) {
        // If no fee, return initial amount
        if (_protocolFee == 0) return _amount;

        // Payout protocol fee
        _handlePayout(_protocolTreasury, _protocolFee, _payoutCurrency, 50000);

        // Return remaining amount
        return _amount - _protocolFee;
    }

    /**
     * 
     * @notice Handle an incoming funds transfer, ensuring the sent amount is valid and the sender is solvent
     * @param _buyer The address of buyer.
     * @param _amount The amount to be received
     * @param _currency The currency to receive funds in, or address(0) for ETH
     * @param _to The address of sending tokens to.
     */
    function _handleIncomingTransfer(
        address _buyer, 
        uint256 _amount, 
        address _currency,
        address _to
    ) 
    internal {
        if (_currency == address(0)) {
            require(msg.value >= _amount, "_handleIncomingTransfer msg value less than expected amount");
        } else {
            // We must check the balance that was actually transferred to this contract,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20 token = IERC20(_currency);
            uint256 beforeBalance = token.balanceOf(_to);
            TokenUtils.transfer(IERC20(_currency), _buyer, _amount, _to);
            // IERC20(_currency).safeTransferFrom(_buyer, _to, _amount);
            uint256 afterBalance = token.balanceOf(_to);
            require(beforeBalance + _amount == afterBalance, "_handleIncomingTransfer token transfer call did not transfer expected amount");
        }
    }

    /**
     * @notice Pays out the amount to all curators proportionally.
     * @param _tokenContract The NFT contract address to get curation information from
     * @param _tokenId, The Token ID to get curation information from
     * @param _amount The sale amount to pay out.
     * @param _payoutCurrency The currency to pay out
     * @param _curationIds the list of curation id, who act curators.
     */
    function _handleCurationsPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256[] memory _curationIds,
        address[] memory _allocationIds
    ) internal returns (uint256){
        if (_amount == 0) return _amount;

        // Store the number of recipients
        uint256 numCurations = _curationIds.length;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient, amount, and curationBps.
        address recipient;
        uint256 amount;
        uint32 curationBps;

        // Payout each royalty
        for (uint256 i = 0; i < numCurations; ) {
            // Cache the recipient and amount
            // recipient = BardsHub(HUB).curationDataOf(_curationIds[i]).treasury;
            curationBps = BardsHub(HUB).curationDataOf(_curationIds[i]).curationBps;

            amount = (amountRemaining * (1 - curationBps)) / Constants.MAX_BPS;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            // _handlePayout(recipient, amount, _payoutCurrency, 50000);
            bardsStaking().collect(
                _payoutCurrency, 
                amount, 
                _allocationIds[i]
            );

            emit Events.CurationFeePayout(
                _tokenContract, 
                _tokenId, 
                recipient, 
                amount, 
                block.timestamp
            );

            // Cannot underflow as remaining amount is ensured to be greater than or equal to _amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
            if (amountRemaining == 0) break;
        }

        return _amount - amountRemaining;
    }

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     */
    function _handleStakingPayout(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    ) internal {
        bardsStaking().collectStakingFees(
            _curationId,
            _currency,
            _tokens
        );
    }

    /**
     * @notice Pays out the amount to all sellers proportionally.
     * @param _tokenContract The NFT contract address to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The sale amount to pay out.
     * @param _payoutCurrency The currency to pay out
     * @param _sellerFundsRecipients The addresses where funds are sent after the trade.
     * @param _sellerBpses The fee that is sent to the sellers.
     */
    function _handleSellersSplitPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        address[] memory _sellerFundsRecipients,
        uint32[] memory _sellerBpses
    ) internal returns (uint256){
        if (_amount == 0) return _amount;

        // Store the number of recipients
        uint256 numRecipients = _sellerFundsRecipients.length;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient and amount
        address recipient;
        uint256 amount;

        // Payout each royalty
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            recipient = _sellerFundsRecipients[i];
            amount = (_amount * _sellerBpses[i]) / Constants.MAX_BPS;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            _handlePayout(recipient, amount, _payoutCurrency, 50000);

            emit Events.SellFeePayout(_tokenContract, _tokenId, recipient, amount, block.timestamp);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to _amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        return amountRemaining;
    }

    /**
     * 
     * @notice Pays out royalties for given NFTs
     * @param _tokenContract The NFT contract address to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The total sale amount
     * @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
     * @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
     * @return The remaining funds after paying out royalties
     */
    function _handleRoyaltyPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 _gasLimit
    ) internal returns (uint256, bool) {
        // If no gas limit was provided or provided gas limit greater than gas left, just pass the remaining gas.
        uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;

        // External call ensuring contract doesn't run out of gas paying royalties
        try this._handleRoyaltyEnginePayout{gas: gas}(_tokenContract, _tokenId, _amount, _payoutCurrency) returns (uint256 remainingFunds) {
            // Return remaining amount if royalties payout succeeded
            return (remainingFunds, true);
        } catch {
            // Return initial amount if royalties payout failed
            return (_amount, false);
        }
    }

    /**
     * @notice Pays out royalties for NFTs based on the information returned by the royalty engine
     * @dev This method is external to enable setting a gas limit when called - see `_handleRoyaltyPayout`.
     * @param _tokenContract The NFT Contract to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The total sale amount
     * @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
     * @return The remaining funds after paying out royalties
     */
    function _handleRoyaltyEnginePayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) external payable returns (uint256) {
        // Ensure the caller is the contract
        require(msg.sender == address(this), "_handleRoyaltyEnginePayout only self callable");

        // Get the royalty recipients and their associated amounts
        (
            address payable[] memory recipients, 
            uint256[] memory amounts
        ) = royaltyEngine.getRoyalty(_tokenContract, _tokenId, _amount);

        // Store the number of recipients
        uint256 numRecipients = recipients.length;

        // If there are no royalties, return the initial amount
        if (numRecipients == 0) return _amount;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient and amount
        address recipient;
        uint256 amount;

        // Payout each royalty
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            recipient = recipients[i];
            amount = amounts[i];

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            _handlePayout(recipient, amount, _payoutCurrency, 50000);

            emit Events.RoyaltyPayout(_tokenContract, _tokenId, recipient, amount, block.timestamp);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to royalty amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        return amountRemaining;
    }

    /**
     * @notice Handle an outgoing funds transfer
     * @dev Wraps ETH in WETH if the receiver cannot receive ETH, noop if the funds to be sent are 0 or recipient is invalid
     * @param _dest The destination for the funds
     * @param _amount The amount to be sent
     * @param _currency The currency to send funds in, or address(0) for ETH
     * @param _gasLimit The gas limit to use when attempting a payment (if 0, gasleft() is used)
     */
    function _handlePayout(
        address _dest,
        uint256 _amount,
        address _currency,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0 || _dest == address(0)) {
            return;
        }

        // Handle ETH payment
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "_handlePayout insolvent");

            // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
            uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;
            (bool success, ) = _dest.call{value: _amount, gas: gas}("");
            // If the ETH transfer fails (sigh), wrap the ETH and try send it as WETH.
            if (!success) {
                weth.deposit{value: _amount}();
                // IERC20(address(weth)).safeTransferFrom(stakingAddress, _dest, _amount);
                TokenUtils.transfer(IERC20(address(weth)), stakingAddress, _amount, _dest);
            }
        } else {
            // IERC20(_currency).safeTransferFrom(stakingAddress, _dest, _amount);
            TokenUtils.transfer(IERC20(_currency), stakingAddress, _amount, _dest);
        }
    }
}
