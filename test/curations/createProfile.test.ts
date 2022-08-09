import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ERRORS } from '../utils/Errors';

import { 
	MOCK_PROFILE_CONTENT_URI,
	MOCK_PROFILE_HANDLE,
	ZERO_ADDRESS
 } from "../utils/Constants";

import {
	governance,
	bardsHub,
	makeSuiteCleanRoom,
	userAddress,
	userTwo,
	userTwoAddress,
	errorsLib,
	fixPriceMarketModule
} from '../__setup.test';

makeSuiteCleanRoom('Profile Creation', function () {
	context('Generic', function () {
		context('Negatives', function () {
			it('User should fail to create a profile with a handle longer than 31 bytes', async function () {
				const val = '11111111111111111111111111111111';
				expect(val.length).to.eq(32);
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: val,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
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
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: '',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
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
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'Egg',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
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
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: 'egg?',
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.HANDLE_CONTAINS_INVALID_CHARACTERS
				);
			});

			it('User should fail to create a profile with a unwhitelisted follow module', async function () {
				await expect(
					bardsHub.createProfile({
						to: userAddress,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: userAddress,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			// it('User should fail to create a profile with with invalid market module data format', async function () {
			// 	await expect(
			// 		bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
			// 	).to.not.be.reverted;

			// 	await expect(
			// 		bardsHub.createProfile({
			// 			to: userAddress,
			// 			profileId: 0,
			// 			curationId: 0,
			// 			tokenContractPointed: ZERO_ADDRESS,
			// 			tokenIdPointed: 0,
			// 			handle: MOCK_PROFILE_HANDLE,
			// 			contentURI: MOCK_PROFILE_CONTENT_URI,
			// 			marketModule: fixPriceMarketModule.address,
			// 			marketModuleInitData: [0x12, 0x34, 0x56],
			// 			mintModule: ZERO_ADDRESS,
			// 			mintModuleInitData: [],
			// 			curationMetaData: []
			// 		})
			// 	).to.be.revertedWith(
			// 		ERRORS.NO_REASON_ABI_DECODE
			// 	);
			// });

			it('User should fail to create a profile when they are not a whitelisted profile creator', async function () {
				await expect(
					bardsHub.connect(governance).whitelistProfileCreator(userAddress, false)
				).to.not.be.reverted;

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: MOCK_PROFILE_HANDLE,
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: userAddress,
						marketModuleInitData: [],
						mintModule: ZERO_ADDRESS,
						mintModuleInitData: [],
						curationMetaData: []
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.PROFILE_CREATOR_NOT_WHITELISTED
				);
			});
		});
	});
})