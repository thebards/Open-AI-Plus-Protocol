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
	mockMintModuleInitData
} from '../__setup.test';
import { DataTypes } from '../../typechain-types/contracts/core/BardsHub';



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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS
				);
			});

			it('User should fail to create a profile with with invalid market module data format', async function () {
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: mockMintModuleInitData,
						curationMetaData: mockCurationMetaData
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
					mintModule: ZERO_ADDRESS,
					mintModuleInitData: mockMintModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
			expect(await bardsHub.ownerOf(FIRST_PROFILE_ID)).to.eq(userTwoAddress);
		});
	});
})