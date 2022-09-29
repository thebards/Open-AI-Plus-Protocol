import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber} from 'ethers';
import { ERRORS } from '../utils/Errors';

import { 
	MOCK_PROFILE_CONTENT_URI,
	MOCK_PROFILE_HANDLE,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS
 } from "../utils/Constants";

import { 
	getTimestamp,
	createProfileReturningTokenId
} from "../utils/Helpers";

import {
	abiCoder,
	CurationType,
	governance,
	bardsHub,
	makeSuiteCleanRoom,
	userAddress,
	userTwo,
	userTwoAddress,
	errorsLib,
	fixPriceMarketModule,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	bardsCurationToken,
	transferMinter
} from '../__setup.test';
import { DataTypes } from '../../build/types/contracts/core/BardsHub';



makeSuiteCleanRoom('Profile Creation', function () {
	context('Generic', function () {
		context('Negatives Stories', function () {
			it('User should fail to create a profile with a handle longer than 31 bytes', async function () {
				const val = '11111111111111111111111111111111';
				expect(val.length).to.eq(32);
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: val,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.INVALID_HANDLE_LENGTH
				);
			});

			it('User should fail to create a profile with an empty handle (0 length bytes)', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: '',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.INVALID_HANDLE_LENGTH
				);
			});

			it('User should fail to create a profile with a handle with a capital letter', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'Egg',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS
				);
			});

			it('User should fail to create a profile with a handle with an invalid character', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'egg?',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS
				);
			});

			it('User should fail to create a profile with invalid market module data format', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const faultMarketModuleInitData = abiCoder.encode(
					['address', 'uint256', 'address', 'address'],
					[ZERO_ADDRESS, 0, ZERO_ADDRESS, ZERO_ADDRESS]
				);

				await expect(
					bardsHub.createProfile({
						to: userTwoAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: faultMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithoutReason;
			});

			it('User should fail to create a profile with a unwhitelisted market module', async function () {
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
						marketModule: userAddress,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			it('User should fail to create a profile when they are not a whitelisted profile creator', async function () {
				await expect(
					bardsHub.connect(governance).whitelistProfileCreator(userAddress, false)
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
						marketModule: userAddress,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PROFILE_CREATOR_NOT_WHITELISTED
				);
			});
		});


	});

	context('Stories', function () {
		it('User should be able to create a profile with a handle, receive an NFT and the handle should resolve to the NFT ID, userTwo should do the same', async function () {
			let timestamp: any;
			let owner: string;
			let totalSupply: BigNumber;
			let profileId: BigNumber;
			let mintTimestamp: BigNumber;
			let tokenData: DataTypes.TokenDataStruct;

			expect(
				await createProfileReturningTokenId({
					vars: {
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
					},
				})
			).to.eq(FIRST_PROFILE_ID);

			timestamp = await getTimestamp();
			owner = await bardsHub.ownerOf(FIRST_PROFILE_ID);
			totalSupply = await bardsHub.totalSupply();
			profileId = await bardsHub.getProfileIdByHandle(MOCK_PROFILE_HANDLE);
			mintTimestamp = await bardsHub.mintTimestampOf(FIRST_PROFILE_ID);
			tokenData = await bardsHub.tokenDataOf(FIRST_PROFILE_ID);

			expect(owner).to.eq(userAddress);
			expect(totalSupply).to.eq(FIRST_PROFILE_ID);
			expect(profileId).to.eq(FIRST_PROFILE_ID);
			expect(mintTimestamp).to.eq(timestamp);
			expect(tokenData.owner).to.eq(userAddress);
			expect(tokenData.mintTimestamp).to.eq(timestamp);
			expect(await bardsHub.curationBpsOf(FIRST_PROFILE_ID)).to.eq(DEFAULT_CURATION_BPS);
			expect(await bardsHub.stakingBpsOf(FIRST_PROFILE_ID)).to.eq(DEFAULT_STAKING_BPS);
			
			const secondProfileId = FIRST_PROFILE_ID + 1;
			const secondProfileHandle = '2nd_profile';
			expect(
				await createProfileReturningTokenId({
					sender: userTwo,
					vars: {
						to: userTwoAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: secondProfileHandle,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					},
				})
			).to.eq(secondProfileId);

			timestamp = await getTimestamp();
			owner = await bardsHub.ownerOf(secondProfileId);
			totalSupply = await bardsHub.totalSupply();
			profileId = await bardsHub.getProfileIdByHandle(secondProfileHandle);
			mintTimestamp = await bardsHub.mintTimestampOf(secondProfileId);
			tokenData = await bardsHub.tokenDataOf(secondProfileId);

			expect(owner).to.eq(userTwoAddress);
			expect(totalSupply).to.eq(secondProfileId);
			expect(profileId).to.eq(secondProfileId);
			expect(mintTimestamp).to.eq(timestamp);
			expect(tokenData.owner).to.eq(userTwoAddress);
			expect(tokenData.mintTimestamp).to.eq(timestamp);
			expect(await bardsHub.curationBpsOf(secondProfileId)).to.eq(DEFAULT_CURATION_BPS);
			expect(await bardsHub.stakingBpsOf(secondProfileId)).to.eq(DEFAULT_STAKING_BPS);
		});

		it('Should return the expected token IDs when creating profiles', async function () {
			expect(
				await createProfileReturningTokenId({
					vars: {
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'token.id_1',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					},
				})
			).to.eq(FIRST_PROFILE_ID);

			const secondProfileId = FIRST_PROFILE_ID + 1;
			expect(
				await createProfileReturningTokenId({
					sender: userTwo,
					vars: {
						to: userTwoAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'token.id_2',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					},
				})
			).to.eq(secondProfileId);

			const thirdProfileId = secondProfileId + 1;
			expect(
				await createProfileReturningTokenId({
					vars: {
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'token.id_3',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					},
				})
			).to.eq(thirdProfileId);
		});

		it('User should be able to create a profile with a handle including "-" and "_" characters', async function () {
			await expect(
				bardsHub.createProfile({
					to: userAddress,
					curationType: CurationType.Profile,
					profileId: 0,
					curationId: 0,
					tokenContractPointed: ZERO_ADDRESS,
					tokenIdPointed: 0,
					handle: 'morse--__-_--code',
					contentURI: MOCK_PROFILE_CONTENT_URI,
					marketModule: ZERO_ADDRESS,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;
		});

		it('User should be able to create a profile with a handle 16 bytes long, then fail to create with the same handle, and create again with a different handle', async function () {
			await expect(
				bardsHub.createProfile({
					to: userAddress,
					curationType: CurationType.Profile,
					profileId: 0,
					curationId: 0,
					tokenContractPointed: ZERO_ADDRESS,
					tokenIdPointed: 0,
					handle: '123456789012345',
					contentURI: MOCK_PROFILE_CONTENT_URI,
					marketModule: ZERO_ADDRESS,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;

			await expect(
				bardsHub.createProfile({
					to: userAddress,
					curationType: CurationType.Profile,
					profileId: 0,
					curationId: 0,
					tokenContractPointed: ZERO_ADDRESS,
					tokenIdPointed: 0,
					handle: '123456789012345',
					contentURI: MOCK_PROFILE_CONTENT_URI,
					marketModule: ZERO_ADDRESS,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.be.revertedWithCustomError(
				errorsLib,
				ERRORS.PROFILE_HANDLE_TOKEN
			);

			await expect(
				bardsHub.createProfile({
					to: userAddress,
					curationType: CurationType.Profile,
					profileId: 0,
					curationId: 0,
					tokenContractPointed: ZERO_ADDRESS,
					tokenIdPointed: 0,
					handle: 'abcdefghijklmno',
					contentURI: MOCK_PROFILE_CONTENT_URI,
					marketModule: ZERO_ADDRESS,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;
		});

		it('User should be able to create a profile with a whitelisted market module', async function () {

			const mockMarketModuleInitData = abiCoder.encode(
				['address', 'address', 'uint256', 'address', 'address'],
				[ZERO_ADDRESS, bardsCurationToken.address, 100000, ZERO_ADDRESS, transferMinter.address]
			);

			await expect(
				bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
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
					marketModule: fixPriceMarketModule.address,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: fixPriceMarketModule.address,
					minterMarketModuleInitData: mockMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;
		});

		it('User should create a profile for userTwo', async function () {
			await expect(
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
			).to.not.be.reverted;
			expect(await bardsHub.ownerOf(FIRST_PROFILE_ID)).to.eq(userTwoAddress);
		});
	});
})