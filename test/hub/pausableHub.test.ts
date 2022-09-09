import { zeroPad } from '@ethersproject/bytes';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
	MAX_UINT256,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	cancelWithPermitForAll,
	getSetMarketModuleWithSigParts,
	getSetCurationContentURIWithSigParts,
	getCreateCurationWithSigParts,
	deriveChannelKey
} from '../utils/Helpers';
import {
	abiCoder,
	bardsHub,
	ProtocolState,
	CurationType,
	makeSuiteCleanRoom,
	testWallet,
	governance,
	userTwoAddress,
	userTwo,
	userAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	errorsLib,
	fixPriceMarketModule,
	bardsCurationToken,
	transferMinter
} from '../__setup.test';

makeSuiteCleanRoom('Pausable Hub', function () {
	context('Common Stories', function () {
		context('Negatives Stories', function () {
			it('User should fail to set the state on the hub', async function () {
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

			it('Governance should set user as emergency admin, user should fail to set protocol state to PublishingPaused or Paused from Paused', async function () {
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
			it('Governance should set user as emergency admin, user sets protocol state but fails to set emergency admin, governance sets emergency admin to the zero address, user fails to set protocol state', async function () {
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
				expect(
					await bardsHub.getState()
				).to.eq(ProtocolState.Paused);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;
				expect(
					await bardsHub.getState()
				).to.eq(ProtocolState.CurationPaused);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;
				expect(
					await bardsHub.getState()
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

	context('Paused State Stories', function () {
		context('Stories', async function () {
			it('User should create a profile, governance should pause the hub, transferring the profile should fail', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				await expect(
					bardsHub.transferFrom(userAddress, userAddress, FIRST_PROFILE_ID)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);
			});

			it('Governance should pause the hub, profile creation should fail, then governance unpauses the hub and profile creation should work', async function () {
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, setting market module should fail, then governance unpauses the hub and setting market module should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, setting market module with sig should fail, then governance unpauses the hub and setting market module with sig should work', async function () {
				await expect(
					bardsHub.connect(testWallet).createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, setting curation URI should fail, then governance unpauses the hub and setting curation URI should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setCurationContentURI(FIRST_PROFILE_ID, MOCK_PROFILE_CONTENT_URI)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setCurationContentURI(FIRST_PROFILE_ID, MOCK_PROFILE_CONTENT_URI)
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, setting curation URI with sig should fail, then governance unpauses the hub and setting curation URI should work', async function () {
				await expect(
					bardsHub.connect(testWallet).createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetCurationContentURIWithSigParts(
					FIRST_PROFILE_ID,
					MOCK_PROFILE_CONTENT_URI,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setCurationContentURIWithSig({
						curationId: FIRST_PROFILE_ID,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setCurationContentURIWithSig({
						curationId: FIRST_PROFILE_ID,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, burning should fail, then governance unpauses the hub and burning should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				await expect(
					bardsHub.burn(FIRST_PROFILE_ID)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.burn(FIRST_PROFILE_ID)
				).to.not.be.reverted;
			});

		});
	});

	context('CurationPaused State', function () {
		context('Stories', async function () {
			it('Governance should pause Curation, profile creation should work', async function () {
				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, setting follow module should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, setting market module with sig should work', async function () {
				await expect(
					bardsHub.connect(testWallet).createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, setting profile URI should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.setCurationContentURI(FIRST_PROFILE_ID, MOCK_PROFILE_CONTENT_URI)
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, setting profile URI with sig should work', async function () {
				await expect(
					bardsHub.connect(testWallet).createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetCurationContentURIWithSigParts(
					FIRST_PROFILE_ID,
					MOCK_PROFILE_CONTENT_URI,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setCurationContentURIWithSig({
						curationId: FIRST_PROFILE_ID,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, burning should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.burn(FIRST_PROFILE_ID)
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, posting should fail, then governance unpauses the hub and posting should work', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createCuration({
						to: userAddress,
						curationType: CurationType.Content,
						profileId: FIRST_PROFILE_ID,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.CURATION_PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createCuration({
						to: userAddress,
						curationType: CurationType.Content,
						profileId: FIRST_PROFILE_ID,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;
			});

			it('Governance should pause publishing, posting with sig should fail, then governance unpauses the hub and posting with sig should work', async function () {
				await expect(
					bardsHub.connect(testWallet).createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					ZERO_ADDRESS,
					mockMinterMarketModuleInitData,
					mockCurationMetaData,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.createCurationWithSig({
						curationType: CurationType.Content,
						profileId: FIRST_PROFILE_ID,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.CURATION_PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;

				await expect(
					bardsHub.createCurationWithSig({
						curationType: CurationType.Content,
						profileId: FIRST_PROFILE_ID,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;
			});

			it('Governance should pause the hub, collecting should fail, then governance unpauses the hub and collecting should work', async function () {

				const mockMarketModuleInitData = abiCoder.encode(
					['address', 'address', 'uint256', 'address', 'address'],
					[userAddress, bardsCurationToken.address, 100000, userAddress, transferMinter.address]
				);
				const mockMinterMarketModuleInitData = abiCoder.encode(
					['address', 'address', 'uint256', 'address', 'address'],
					[userAddress, bardsCurationToken.address, 100000, userAddress, transferMinter.address]
				);
				const mockCurationMetaData = abiCoder.encode(
					['address[]', 'address[]', 'uint32[]', 'uint32', 'uint32'],
					[[userAddress], [userAddress], [1000000], DEFAULT_CURATION_BPS, DEFAULT_STAKING_BPS]
				);

				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;
				await expect(
					bardsHub.connect(governance).whitelistMintModule(transferMinter.address, true)
				).to.not.be.reverted;

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.createCuration({
						to: userAddress,
						curationType: CurationType.Content,
						profileId: FIRST_PROFILE_ID,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Paused)
				).to.not.be.reverted;

				const channelKey = deriveChannelKey();
				const allocationID = channelKey.address;

				await expect(
					bardsHub.collect({
						collector: userAddress,
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						allocationIds: [],
						collectMetaData: [],
						fromCuration: false
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PAUSED
				);

				await expect(
					bardsHub.connect(governance).setState(ProtocolState.Unpaused)
				).to.not.be.reverted;
				
				// console.log(await bardsHub.getCuration(FIRST_PROFILE_ID + 1));

				// console.log(await fixPriceMarketModule.getMarketData(bardsHub.address, FIRST_PROFILE_ID));
				// console.log(await fixPriceMarketModule.getMarketData(bardsHub.address, FIRST_PROFILE_ID + 1));

				// await expect(
				// 	bardsHub.collect({
				// 		collector: userAddress,
				// 		curationId: FIRST_PROFILE_ID + 1,
				// 		curationIds: [],
				// 		allocationIds: [],
				// 		collectMetaData: [],
				// 		fromCuration: false
				// 	})
				// ).to.be.revertedWithCustomError(
				// 	errorsLib,
				// 	ERRORS.PAUSED
				// );
			});
			

		});
	});

});