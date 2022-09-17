import { zeroPad } from '@ethersproject/bytes';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
	MAX_UINT256,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	MOCK_PROFILE_HANDLE2
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	cancelWithPermitForAll,
	deriveChannelKey,
	getSetAllocationIdWithSigParts
} from '../utils/Helpers';
import {
	abiCoder,
	bardsHub,
	CurationType,
	makeSuiteCleanRoom,
	testWallet,
	governance,
	userAddress,
	userTwo,
	userTwoAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	errorsLib,
	fixPriceMarketModule,
	bardsCurationToken,
	transferMinter,
} from '../__setup.test';

makeSuiteCleanRoom('Setting Allocation ID', function () {
	const channelKey = deriveChannelKey();
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
					marketModule: ZERO_ADDRESS,
					marketModuleInitData: mockMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('UserTwo should fail to set the default profile as a profile owned by user 1', async function () {
				await expect(
					bardsHub.connect(userTwo).setAllocationId({
						curationId: FIRST_PROFILE_ID + 1,
						allocationId: channelKey.address
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_OWNER_OR_APPROVED
				);
			});
		});

		context('Stories', function () {
			it('User should set the allocation Id', async function () {
				await expect(
					bardsHub.setAllocationId({
						curationId: FIRST_PROFILE_ID + 1,
						allocationId: channelKey.address
					})
				).to.not.be.reverted;
				expect(await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 1)).to.eq(channelKey.address);
			});

			it('User should set the allocation ID and then be able to unset it', async function () {
				await expect(
					bardsHub.setAllocationId({
						curationId: FIRST_PROFILE_ID + 1,
						allocationId: channelKey.address
					})
				).to.not.be.reverted;

				await expect(
					bardsHub.setAllocationId({
						curationId: FIRST_PROFILE_ID + 1,
						allocationId: ZERO_ADDRESS
					})
				).to.not.be.reverted;
				expect(await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 1)).to.eq(ZERO_ADDRESS);
			});

			it('UserTwo should fail to set the allocation Id for the curation owned by User', async function () {
				await expect(
					bardsHub.connect(userTwo).setAllocationId({
						curationId: FIRST_PROFILE_ID + 1,
						allocationId: channelKey.address
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_OWNER_OR_APPROVED
				);
			});

		});

		context('Meta-tx Stories', function () {

			context('Negatives Stories', function () {
				it('TestWallet should fail to set a allocation ID with sig with signature deadline mismatch', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 1,
						channelKey.address,
						nonce,
						'0'
					);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 1,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: MAX_UINT256,
							},
						})
					).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);

				});

				it('TestWallet should fail to set a allocation ID with sig with invalid deadline', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 1,
						channelKey.address,
						nonce,
						'0'
					);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 1,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: '0',
							},
						})
					).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);

				});

				it('TestWallet should fail to set a allocation ID with sig with invalid nonce', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 1,
						channelKey.address,
						nonce + 1,
						MAX_UINT256
					);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 1,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: MAX_UINT256,
							},
						})
					).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);

				});

				it('TestWallet should sign attempt to set allocation ID with sig, cancel with empty permitForAll, then fail to set default profile with sig', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 1,
						channelKey.address,
						nonce,
						MAX_UINT256
					);

					await cancelWithPermitForAll();

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 1,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: MAX_UINT256,
							},
						})
					).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);

				});

			});

			context('Stories', function () {
				beforeEach(async function () {
					await expect(
						bardsHub.connect(testWallet).createProfile({
							to: testWallet.address,
							curationType: CurationType.Profile,
							profileId: 0,
							curationId: 0,
							tokenContractPointed: ZERO_ADDRESS,
							tokenIdPointed: 0,
							handle: MOCK_PROFILE_HANDLE2,
							contentURI: MOCK_PROFILE_CONTENT_URI,
							marketModule: ZERO_ADDRESS,
							marketModuleInitData: mockMarketModuleInitData,
							minterMarketModule: ZERO_ADDRESS,
							minterMarketModuleInitData: mockMarketModuleInitData,
							curationMetaData: mockCurationMetaData
						})
					).to.not.be.reverted;

					await expect(
						bardsHub.connect(testWallet).createCuration({
							to: testWallet.address,
							curationType: CurationType.Content,
							profileId: FIRST_PROFILE_ID + 2,
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

				it('TestWallet should set the allocation ID with sig', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 3,
						channelKey.address,
						nonce,
						MAX_UINT256
					);

					const allocationIdBeforeUse = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 1);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 3,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: MAX_UINT256,
							},
						})
					).to.not.be.reverted;

					const allocationIdAfter = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 3);

					expect(allocationIdBeforeUse).to.eq(ZERO_ADDRESS);
					expect(allocationIdAfter).to.eq(channelKey.address);
				});

				it('TestWallet should set the allocation ID with sig and then be able to unset it', async function () {
					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const { v, r, s } = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 3,
						channelKey.address,
						nonce,
						MAX_UINT256
					);

					const allocationIdBeforeUse = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 3);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 3,
							allocationId: channelKey.address,
							sig: {
								v,
								r,
								s,
								deadline: MAX_UINT256,
							},
						})
					).to.not.be.reverted;

					const allocationIdAfter = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 3);

					expect(allocationIdBeforeUse).to.eq(ZERO_ADDRESS);
					expect(allocationIdAfter).to.eq(channelKey.address);

					const nonce2 = (await bardsHub.sigNonces(testWallet.address)).toNumber();
					const signature2 = await getSetAllocationIdWithSigParts(
						FIRST_PROFILE_ID + 3,
						ZERO_ADDRESS,
						nonce2,
						MAX_UINT256
					);

					const allocationIDBeforeUse2 = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 3);

					await expect(
						bardsHub.setAllocationIdWithSig({
							curationId: FIRST_PROFILE_ID + 3,
							allocationId: ZERO_ADDRESS,
							sig: {
								v: signature2.v,
								r: signature2.r,
								s: signature2.s,
								deadline: MAX_UINT256,
							},
						})
					).to.not.be.reverted;

					const allocationIdAfter2 = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID + 3);

					expect(allocationIDBeforeUse2).to.eq(channelKey.address);
					expect(allocationIdAfter2).to.eq(ZERO_ADDRESS);
				});
				
			});
		});
	});

})