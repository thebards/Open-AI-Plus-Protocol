import { zeroPad } from '@ethersproject/bytes';
import { TransactionReceipt } from '@ethersproject/providers';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { constants, utils, BytesLike, BigNumber, Signature, Event } from 'ethers'
import { BardsStaking__factory, TransparentUpgradeableProxy__factory } from '../../dist/types';
const { AddressZero, MaxUint256 } = constants
import {
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS,
	BARDS_HUB_NFT_NAME,
	BARDS_HUB_NFT_SYMBOL,
	PROTOCOL_FEE,
	DEFAULTS
} from '../utils/Constants';
import {
	toBCT,
	getTimestamp,
	approveToken,
	waitForTx,
	matchEvent
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
	userAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	fixPriceMarketModule,
	bardsCurationToken,
	transferMinter,
	user,
	deployer,
	bardsHubImpl,
	governanceAddress,
	deployerAddress,
	bardsDaoData,
	daoTreasuryAddress,
	epochManager,
	userTwo,
} from '../__setup.test';

makeSuiteCleanRoom('Events', function () {
	let receipt: TransactionReceipt;

	context('Misc', function () {
		it('Proxy initialization should emit expected events', async function () {
			let data = bardsHubImpl.interface.encodeFunctionData('initialize', [
				BARDS_HUB_NFT_NAME,
				BARDS_HUB_NFT_SYMBOL,
				governanceAddress,
				DEFAULTS.epochs.lengthInBlocks
			]);
			let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsHubImpl.address,
				deployerAddress,
				data
			);

			receipt = await waitForTx(proxy.deployTransaction, true);

			expect(receipt.logs.length).to.eq(6);
			matchEvent(receipt, 'Upgraded', [bardsHubImpl.address], proxy);
			matchEvent(receipt, 'AdminChanged', [ZERO_ADDRESS, deployerAddress], proxy);
			matchEvent(receipt, 'GovernanceSet', [
				deployerAddress,
				ZERO_ADDRESS,
				governanceAddress,
				await getTimestamp(),
			]);
			matchEvent(receipt, 'StateSet', [
				deployerAddress,
				ProtocolState.Unpaused,
				ProtocolState.Paused,
				await getTimestamp(),
			]);
			matchEvent(receipt, 'BaseInitialized', [
				BARDS_HUB_NFT_NAME,
				BARDS_HUB_NFT_SYMBOL,
				await getTimestamp(),
			]);
			matchEvent(receipt, 'CooldownBlocksUpdated', [
				0,
				DEFAULTS.epochs.lengthInBlocks,
				await getTimestamp(),
			]);
		});
	});

	context('Hub Governance', function () {
		it('Governance change should emit expected event', async function () {
			receipt = await waitForTx(bardsHub.connect(governance).setGovernance(userAddress));
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'GovernanceSet', [
				governanceAddress,
				governanceAddress,
				userAddress,
				await getTimestamp(),
			]);
		});

		it('Emergency admin change should emit expected event', async function () {
			receipt = await waitForTx(bardsHub.connect(governance).setEmergencyAdmin(userAddress));
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'EmergencyAdminSet', [
				governanceAddress,
				ZERO_ADDRESS,
				userAddress,
				await getTimestamp(),
			]);
		});

		it('Protocol state change by governance should emit expected event', async function () {
			receipt = await waitForTx(bardsHub.connect(governance).setState(ProtocolState.Paused));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'StateSet', [
				governanceAddress,
				ProtocolState.Unpaused,
				ProtocolState.Paused,
				await getTimestamp(),
			]);

			receipt = await waitForTx(
				bardsHub.connect(governance).setState(ProtocolState.CurationPaused)
			);

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'StateSet', [
				governanceAddress,
				ProtocolState.Paused,
				ProtocolState.CurationPaused,
				await getTimestamp(),
			]);

			receipt = await waitForTx(bardsHub.connect(governance).setState(ProtocolState.Unpaused));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'StateSet', [
				governanceAddress,
				ProtocolState.CurationPaused,
				ProtocolState.Unpaused,
				await getTimestamp(),
			]);
		});

		it('Protocol state change by emergency admin should emit expected events', async function () {
			await waitForTx(bardsHub.connect(governance).setEmergencyAdmin(userAddress));

			receipt = await waitForTx(bardsHub.connect(user).setState(ProtocolState.CurationPaused));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'StateSet', [
				userAddress,
				ProtocolState.Unpaused,
				ProtocolState.CurationPaused,
				await getTimestamp(),
			]);

			receipt = await waitForTx(bardsHub.connect(user).setState(ProtocolState.Paused));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'StateSet', [
				userAddress,
				ProtocolState.CurationPaused,
				ProtocolState.Paused,
				await getTimestamp(),
			]);
		});

		it('Market module whitelisting functions should emit expected event', async function () {
			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistMarketModule(userAddress, true)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'MarketModuleWhitelisted', [userAddress, true, await getTimestamp()]);

			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistMarketModule(userAddress, false)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'MarketModuleWhitelisted', [userAddress, false, await getTimestamp()]);
		});

		it('Minter module whitelisting functions should emit expected event', async function () {
			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistMinterModule(userAddress, true)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'MinterModuleWhitelisted', [userAddress, true, await getTimestamp()]);

			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistMinterModule(userAddress, false)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'MinterModuleWhitelisted', [userAddress, false, await getTimestamp()]);
		});

		it('Profile Creator whitelisting functions should emit expected event', async function () {
			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistProfileCreator(userAddress, true)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProfileCreatorWhitelisted', [userAddress, true, await getTimestamp()]);

			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistProfileCreator(userAddress, false)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProfileCreatorWhitelisted', [userAddress, false, await getTimestamp()]);
		});

		it('Protocol currency Creator whitelisting functions should emit expected event', async function () {
			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistCurrency(userAddress, true)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProtocolCurrencyWhitelisted', [userAddress, false, true, await getTimestamp()]);

			receipt = await waitForTx(
				bardsHub.connect(governance).whitelistCurrency(userAddress, false)
			);
			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProtocolCurrencyWhitelisted', [userAddress, true, false, await getTimestamp()]);
		});
	});

	context('Hub Interaction', function () {
		async function createProfile() {
			await waitForTx(
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			);
		}

		it('Profile creation should emit the correct events', async function () {
			receipt = await waitForTx(
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			);

			expect(receipt.logs.length).to.eq(4);

			matchEvent(
				receipt, 
				'Transfer', 
				[
					ZERO_ADDRESS, 
					userAddress, 
					FIRST_PROFILE_ID
				], 
				bardsHubImpl
			);

			matchEvent(
				receipt,
				'ProfileCreated',
				[
					FIRST_PROFILE_ID,
					userAddress,
					userAddress,
					MOCK_PROFILE_HANDLE,
					MOCK_PROFILE_CONTENT_URI,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					ZERO_ADDRESS,
					mockMinterMarketModuleInitData,
					await getTimestamp()
				]
			);

			matchEvent(
				receipt,
				'CurationUpdated',
				[
					FIRST_PROFILE_ID,
					mockCurationMetaData,
					await getTimestamp()
				]
			);

			matchEvent(
				receipt,
				'AllocationCreated',
				[
					FIRST_PROFILE_ID,
					await bardsHub.getAllocationIdById(FIRST_PROFILE_ID),
					await epochManager.currentEpoch(),
					await getTimestamp()
				]
			);
		});

		it('Profile creation for other user should emit the correct events', async function () {
			receipt = await waitForTx(
				bardsHub.createProfile({
					to: userTwoAddress,
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			);
			
			expect(receipt.logs.length).to.eq(4);

			matchEvent(
				receipt,
				'Transfer',
				[
					ZERO_ADDRESS, 
					userTwoAddress, 
					FIRST_PROFILE_ID
				],
				bardsHubImpl
			);

			matchEvent(
				receipt, 
				'ProfileCreated', 
				[
					FIRST_PROFILE_ID,
					userAddress,
					userTwoAddress,
					MOCK_PROFILE_HANDLE,
					MOCK_PROFILE_CONTENT_URI,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					ZERO_ADDRESS,
					mockMinterMarketModuleInitData,
					await getTimestamp()
				]
			);

			matchEvent(
				receipt,
				'CurationUpdated',
				[
					FIRST_PROFILE_ID,
					mockCurationMetaData,
					await getTimestamp()
				]
			);

			matchEvent(
				receipt,
				'AllocationCreated',
				[
					FIRST_PROFILE_ID,
					await bardsHub.getAllocationIdById(FIRST_PROFILE_ID),
					await epochManager.currentEpoch(),
					await getTimestamp()
				]
			);
		});

		it('Setting market module should emit correct events', async function () {
			await createProfile();

			await waitForTx(
				bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
			);

			receipt = await waitForTx(
				bardsHub.setMarketModule({
					curationId: FIRST_PROFILE_ID,
					tokenContract: bardsHub.address,
					tokenId: FIRST_PROFILE_ID,
					marketModule: fixPriceMarketModule.address,
					marketModuleInitData: mockMarketModuleInitData
				})
			);

			expect(receipt.logs.length).to.eq(1);

			matchEvent(
				receipt, 
				'MarketModuleSet', 
				[
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					await getTimestamp(),
				]
			);
		});

		it('Collecting should emit correct events', async function () {
			await createProfile();

			await waitForTx(
				bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
			);

			const mockMarketModuleInitData = abiCoder.encode(
				['address', 'address', 'uint256', 'address', 'address'],
				[ZERO_ADDRESS, bardsCurationToken.address, toBCT(10), ZERO_ADDRESS, transferMinter.address]
			);

			await waitForTx(
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			);

			await expect(
				bardsCurationToken.mint(testWallet.address, toBCT('10000'))
			).to.not.be.reverted;

			await expect(
				bardsHub.setApprovalForAll(transferMinter.address, true)
			).to.not.be.reverted;

			// Allow to transfer tokens for testWallet
			await approveToken(fixPriceMarketModule.address, MaxUint256);

			const collectMetaData = abiCoder.encode(
				['address', 'uint256', 'address', 'address'],
				[bardsHub.address, FIRST_PROFILE_ID + 1, userAddress, testWallet.address]
			);

			receipt = await waitForTx(
				bardsHub.connect(testWallet).collect({
					curationId: FIRST_PROFILE_ID + 1,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				})
			);

			expect(receipt.logs.length).to.eq(9);

			matchEvent(
				receipt, 
				'Collected', 
				[
					testWallet.address,
					FIRST_PROFILE_ID + 1,
					bardsHub.address,
					FIRST_PROFILE_ID + 1,
					collectMetaData,
					await getTimestamp(),
				]
			);
		});

	});

	context('Bards Dao Data Governance', function () {
		it('Governance change should emit expected event', async function () {
			receipt = await waitForTx(bardsDaoData.connect(governance).setGovernance(userAddress));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProtocolGovernanceSet', [
				governanceAddress,
				userAddress,
				await getTimestamp(),
			]);
		});

		it('Treasury change should emit expected event', async function () {
			receipt = await waitForTx(bardsDaoData.connect(governance).setTreasury(userAddress));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProtocolTreasurySet', [
				daoTreasuryAddress,
				userAddress,
				await getTimestamp(),
			]);
		});

		it('Protocol fee change should emit expected event', async function () {
			receipt = await waitForTx(bardsDaoData.connect(governance).setProtocolFee(123));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'ProtocolFeeSet', [
				PROTOCOL_FEE,
				123,
				await getTimestamp(),
			]);
		});

		it('DefaultCurationBps change should emit expected event', async function () {
			receipt = await waitForTx(bardsDaoData.connect(governance).setDefaultCurationBps(123));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'DefaultCurationFeeSet', [
				DEFAULT_CURATION_BPS,
				123,
				await getTimestamp(),
			]);
		});

		it('DefaultStakingBps change should emit expected event', async function () {
			receipt = await waitForTx(bardsDaoData.connect(governance).setDefaultStakingBps(123));

			expect(receipt.logs.length).to.eq(1);
			matchEvent(receipt, 'DefaultStakingFeeSet', [
				DEFAULT_STAKING_BPS,
				123,
				await getTimestamp(),
			]);
		});

	});

})