import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';

import { 
	MAX_UINT256, 
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI
} from '../utils/Constants';

import { ERRORS } from '../utils/Errors';

import { 
	cancelWithPermitForAll, 
	getSetDefaultProfileWithSigParts 
} from '../utils/Helpers';

import {
	bardsHub,
	CurationType,
	makeSuiteCleanRoom,
	testWallet,
	userAddress,
	userTwo,
	userTwoAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	errorsLib,
} from '../__setup.test';

makeSuiteCleanRoom('Default profile Functionality', function () {
	context('Generic Stories', function () {
		beforeEach(async function () {
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
					minterMarketModuleInitData: mockMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('UserTwo should fail to set the default profile as a profile owned by user 1', async function () {
				await expect(
					bardsHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID)
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_OWNER
				);
			});
		});

		context('Stories', function () {
			it('User should set the default profile', async function () {
				await expect(bardsHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);
			});

			it('User should set the default profile and then be able to unset it', async function () {
				await expect(bardsHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

				await expect(bardsHub.setDefaultProfile(0)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(0);
			});

			it('User should set the default profile and then be able to change it to another', async function () {
				await expect(bardsHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

				await expect(
					bardsHub.createProfile({
						to: userAddress,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: new Date().getTime().toString(),
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;

				await expect(bardsHub.setDefaultProfile(2)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(2);
			});

			it('User should set the default profile and then transfer it, their default profile should be unset', async function () {
				await expect(bardsHub.setDefaultProfile(FIRST_PROFILE_ID)).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(FIRST_PROFILE_ID);

				await expect(
					bardsHub.transferFrom(userAddress, userTwoAddress, FIRST_PROFILE_ID)
				).to.not.be.reverted;
				expect(await bardsHub.defaultProfile(userAddress)).to.eq(0);
			});
		});
	});

	context('Meta-tx Stories', function () {
		beforeEach(async function () {
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
					minterMarketModuleInitData: mockMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('TestWallet should fail to set default profile with sig with signature deadline mismatch', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					'0'
				);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
				// .to.be.revertedWithCustomError(
				// 	errorsLib,
				// 	ERRORS.SIGNATURE_INVALID
				// );
			});

			it('TestWallet should fail to set default profile with sig with invalid deadline', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					'0'
				);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: '0',
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
				// .to.be.revertedWithCustomError(
				// 	errorsLib, 
				// 	ERRORS.SIGNATURE_EXPIRED
				// );
			});

			it('TestWallet should fail to set default profile with sig with invalid nonce', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce + 1,
					MAX_UINT256
				);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
				// .to.be.revertedWithCustomError(
				// 	errorsLib, 
				// 	ERRORS.SIGNATURE_INVALID
				// );
			});

			it('TestWallet should sign attempt to set default profile with sig, cancel with empty permitForAll, then fail to set default profile with sig', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					MAX_UINT256
				);

				await cancelWithPermitForAll();

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
				// .to.be.revertedWithCustomError(
				// 	errorsLib, 
				// 	ERRORS.SIGNATURE_INVALID
				// );
			});
		});

		context('Stories', function () {
			it('TestWallet should set the default profile with sig', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					MAX_UINT256
				);

				const defaultProfileBeforeUse = await bardsHub.defaultProfile(testWallet.address);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				const defaultProfileAfter = await bardsHub.defaultProfile(testWallet.address);

				expect(defaultProfileBeforeUse).to.eq(0);
				expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);
			});

			it('TestWallet should set the default profile with sig and then be able to unset it', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					MAX_UINT256
				);

				const defaultProfileBeforeUse = await bardsHub.defaultProfile(testWallet.address);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						wallet: testWallet.address,
						profileId: FIRST_PROFILE_ID,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				const defaultProfileAfter = await bardsHub.defaultProfile(testWallet.address);

				expect(defaultProfileBeforeUse).to.eq(0);
				expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);

				const nonce2 = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const signature2 = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					0,
					nonce2,
					MAX_UINT256
				);

				const defaultProfileBeforeUse2 = await bardsHub.defaultProfile(testWallet.address);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						wallet: testWallet.address,
						profileId: 0,
						sig: {
							v: signature2.v,
							r: signature2.r,
							s: signature2.s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				const defaultProfileAfter2 = await bardsHub.defaultProfile(testWallet.address);

				expect(defaultProfileBeforeUse2).to.eq(FIRST_PROFILE_ID);
				expect(defaultProfileAfter2).to.eq(0);
			});

			it('TestWallet should set the default profile and then be able to change it to another', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID,
					nonce,
					MAX_UINT256
				);

				const defaultProfileBeforeUse = await bardsHub.defaultProfile(testWallet.address);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: FIRST_PROFILE_ID,
						wallet: testWallet.address,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				const defaultProfileAfter = await bardsHub.defaultProfile(testWallet.address);

				expect(defaultProfileBeforeUse).to.eq(0);
				expect(defaultProfileAfter).to.eq(FIRST_PROFILE_ID);

				await expect(
					bardsHub.createProfile({
						to: testWallet.address,
						curationType: CurationType.Profile,
						profileId: 0,
						curationId: 0,
						tokenContractPointed: ZERO_ADDRESS,
						tokenIdPointed: 0,
						handle: new Date().getTime().toString(),
						contentURI: MOCK_PROFILE_CONTENT_URI,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMarketModuleInitData,
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;

				const nonce2 = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const signature2 = await getSetDefaultProfileWithSigParts(
					testWallet.address,
					FIRST_PROFILE_ID + 1,
					nonce2,
					MAX_UINT256
				);

				const defaultProfileBeforeUse2 = await bardsHub.defaultProfile(testWallet.address);

				await expect(
					bardsHub.setDefaultProfileWithSig({
						profileId: 2,
						wallet: testWallet.address,
						sig: {
							v: signature2.v,
							r: signature2.r,
							s: signature2.s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				const defaultProfileAfter2 = await bardsHub.defaultProfile(testWallet.address);

				expect(defaultProfileBeforeUse2).to.eq(1);
				expect(defaultProfileAfter2).to.eq(2);
			});
		});
	});
});