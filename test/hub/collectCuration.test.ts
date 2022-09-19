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
	deriveChannelKey,
	getTimestamp,
	collectReturningTokenPair,
	toBN,
	getCollectWithSigParts
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
	mockFreeMarketModuleInitData,
	mockMinterMarketModuleInitData,
	errorsLib,
	fixPriceMarketModule,
	bardsCurationToken,
	transferMinter,
	user,
	freeMarketModule,
	eventsLib
} from '../__setup.test';

makeSuiteCleanRoom('Collecting', function () {

	beforeEach(async function () {
		await expect(
			bardsHub.connect(governance).whitelistMarketModule(freeMarketModule.address, true)
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
				to: userTwoAddress,
				curationType: CurationType.Content,
				profileId: FIRST_PROFILE_ID,
				curationId: 0,
				tokenContractPointed: ZERO_ADDRESS,
				tokenIdPointed: 0,
				handle: MOCK_PROFILE_HANDLE,
				contentURI: MOCK_PROFILE_CONTENT_URI,
				marketModule: freeMarketModule.address,
				marketModuleInitData: mockFreeMarketModuleInitData,
				minterMarketModule: ZERO_ADDRESS,
				minterMarketModuleInitData: mockMinterMarketModuleInitData,
				curationMetaData: mockCurationMetaData
			})
		).to.not.be.reverted;
	});

	context('Generic Stories', function () {
		context('Stories', function () {
			it('Collecting should work if the collector is the curation owner even', async function () {
				const collectMetaData = abiCoder.encode(
					['address', 'uint256'],
					[ZERO_ADDRESS, 1]
				);

				await expect(
					bardsHub.collect({
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						collectMetaData: collectMetaData,
						fromCuration: false
					})
				).to.not.be.reverted;

			});

			it('Should return the expected token pair when collecting publications', async function () {
				const collectMetaData = abiCoder.encode(
					['address', 'uint256'],
					[ZERO_ADDRESS, 1]
				);

				const tokenPair = await collectReturningTokenPair({
					vars: {
						collector: userAddress,
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						collectMetaData: collectMetaData,
						fromCuration: false
					},
				})

				expect(tokenPair[0]).to.eq(ZERO_ADDRESS);
				expect(tokenPair[1]).to.eq(toBN(1));
			});
		});

		context('Meta-tx Stories', function () {
			context('Negatives Stories', function () {
				it('TestWallet should fail to collect with sig with signature deadline mismatch', async function () {
					const collectMetaData = abiCoder.encode(
						['address', 'uint256'],
						[ZERO_ADDRESS, 1]
					);

					const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

					const { v, r, s } = await getCollectWithSigParts(
						FIRST_PROFILE_ID + 1, 
						collectMetaData, 
						nonce, 
						'0'
					);

					await expect(
						bardsHub.collectWithSig({
							collector: testWallet.address,
							curationId: FIRST_PROFILE_ID + 1,
							curationIds: [],
							collectMetaData: collectMetaData,
							fromCuration: false,
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

			it('TestWallet should fail to collect with sig with invalid deadline', async function () {
				const collectMetaData = abiCoder.encode(
					['address', 'uint256'],
					[ZERO_ADDRESS, 1]
				);
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getCollectWithSigParts(
					FIRST_PROFILE_ID + 1,
					collectMetaData,
					nonce,
					'0'
				);

				await expect(
					bardsHub.collectWithSig({
						collector: testWallet.address,
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						collectMetaData: collectMetaData,
						fromCuration: false,
						sig: {
							v,
							r,
							s,
							deadline: '0',
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
			});

			it('TestWallet should fail to collect with sig with invalid nonce', async function () {
				const collectMetaData = abiCoder.encode(
					['address', 'uint256'],
					[ZERO_ADDRESS, 1]
				);
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getCollectWithSigParts(
					FIRST_PROFILE_ID + 1,
					collectMetaData,
					nonce + 1,
					MAX_UINT256
				);

				await expect(
					bardsHub.collectWithSig({
						collector: testWallet.address,
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						collectMetaData: collectMetaData,
						fromCuration: false,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
			});

			it('TestWallet should sign attempt to collect with sig, cancel via empty permitForAll, fail to collect with sig', async function () {
				const collectMetaData = abiCoder.encode(
					['address', 'uint256'],
					[ZERO_ADDRESS, 1]
				);
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getCollectWithSigParts(
					FIRST_PROFILE_ID + 1,
					collectMetaData,
					nonce,
					MAX_UINT256
				);

				await cancelWithPermitForAll();

				await expect(
					bardsHub.collectWithSig({
						collector: testWallet.address,
						curationId: FIRST_PROFILE_ID + 1,
						curationIds: [],
						collectMetaData: collectMetaData,
						fromCuration: false,
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
	});
});