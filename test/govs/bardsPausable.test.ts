import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ERRORS } from '../utils/Errors';

import { 
	MOCK_PROFILE_HANDLE,
	MAX_UINT256,
	ZERO_ADDRESS
 } from "../utils/Constants";

import {
	governance,
	bardsHub,
	makeSuiteCleanRoom,
	testWallet,
	userAddress,
	userTwoAddress,
	abiCoder,
	ProtocolState,
	errorsLib,
} from '../__setup.test';


makeSuiteCleanRoom('TheBards Hub Pausable', function () {
	context('Common Stories', function () {
		context('Negative Stories', function () {
			it('User should fail to set the state on the bards hub', async function () {
				await expect(
					bardsHub.setState(ProtocolState.Paused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
				await expect(
					bardsHub.setState(ProtocolState.Unpaused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
			});

			it('User should fail to set the emergency admin', async function () {
				await expect(
					bardsHub.setEmergencyAdmin(userAddress)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.NOT_GOVERNANCE
				);
			});

			it('Governance should set user as emergency admin, user should fail to set protocol state to Unpaused', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(userAddress)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.Unpaused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.EMERGENCY_ADMIN_CANNOT_UNPAUSE
				);
			});

			it('Governance should set user as emergency admin, user should fail to set protocol state to CurationPaused or Paused from Paused', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(userAddress)
				).to.not.be.reverted;
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.PAUSED
				);
				await expect(
					bardsHub.setState(ProtocolState.Paused)
				).to.be.revertedWithCustomError(
					errorsLib, 
					ERRORS.PAUSED
				);
			});
		});

		context('Stories', function () {
			it('Governance should set user as emergency admin, user sets protocol state but fails to set emergency admin.', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(userAddress)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.Paused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setEmergencyAdmin(ZERO_ADDRESS)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_GOVERNANCE
				);
			});

			it('Governance sets emergency admin to the zero address, user fails to set protocol state', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(ZERO_ADDRESS)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.Paused)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
				await expect(
					bardsHub.setState(ProtocolState.Unpaused)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_GOVERNANCE_OR_EMERGENCY_ADMIN
				);
			});

			it('Governance should set the protocol state, fetched protocol state should be accurate', async function () {
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;
				expect(await 
					bardsHub.getState()
				).to.eq(ProtocolState.Paused);
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
				expect(await 
					bardsHub.getState()
				).to.eq(ProtocolState.CurationPaused);
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;
				expect(await 
					bardsHub.getState()
				).to.eq(ProtocolState.Unpaused);
			});

			it('Governance should set user as emergency admin, user should set protocol state to CurationPaused, then Paused, then fail to set it to CurationPaused', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(userAddress)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.Paused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);
			});

			it('Governance should set user as emergency admin, user should set protocol state to CurationPaused, then set it to CurationPaused again without reverting', async function () {
				await expect(
					bardsHub.connect(governance).setEmergencyAdmin(userAddress)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
				await expect(
					bardsHub.setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
			});
		});


	});
})