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
	transferMinter,
	emptyMinter
} from '../__setup.test';

makeSuiteCleanRoom('Create Curations', function () {
	context('Generic', function () {
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
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('UserTwo should fail to create curation owned by User', async function () {
				await expect(
					bardsHub.connect(userTwo).createCuration({
						to: userTwoAddress,
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
					ERRORS.NOT_OWNER_OR_APPROVED
				);
			});

			it('User should fail to create curation with an unwhitelisted market module', async function () {
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
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			it('User should fail to create curation with an unwhitelisted minter module', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).whitelistMintModule(emptyMinter.address, false)
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
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: fixPriceMarketModule.address,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MINTER_MODULE_NOT_WHITELISTED
				);
			});

			it('User should fail to create curation with invalid market module data format', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const mockMarketModuleInitData = abiCoder.encode(
					['address', 'address', 'uint256', 'address'],
					[ZERO_ADDRESS, bardsCurationToken.address, 100000, ZERO_ADDRESS]
				);

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
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.be.revertedWithoutReason;
			});
		});

		context('Stories', function () {
			it('User should create a curation with empty market and minter market module data, fetched curation data should be accurate', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
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
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: ZERO_ADDRESS,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;

				const curation = await bardsHub.getCuration(FIRST_PROFILE_ID);

				expect(curation.tokenContractPointed).to.eq(ZERO_ADDRESS);
				expect(curation.tokenIdPointed).to.eq(0);
				expect(curation.contentURI).to.eq(MOCK_PROFILE_CONTENT_URI);
				expect(curation.marketModule).to.eq(fixPriceMarketModule.address);
				expect(curation.minterMarketModule).to.eq(ZERO_ADDRESS);
			});

			it('User should create a post with a whitelisted collect and reference module', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;
				await expect(
					bardsHub.connect(governance).whitelistMintModule(emptyMinter.address, true)
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
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						minterMarketModule: fixPriceMarketModule.address,
						minterMarketModuleInitData: mockMinterMarketModuleInitData,
						curationMetaData: mockCurationMetaData
					})
				).to.not.be.reverted;
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
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('Testwallet should fail to create curation with sig with signature deadline mismatch', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					ZERO_ADDRESS,
					mockMinterMarketModuleInitData,
					mockCurationMetaData,
					nonce,
					'0'
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
						marketModule: fixPriceMarketModule.address,
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
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
				// .to.be.revertedWithCustomError(
				// 	errorsLib,
				// 	ERRORS.SIGNATURE_INVALID
				// );
			});

			it('Testwallet should fail to create curation with sig with invalid deadline', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
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
					'0'
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
							deadline: '0',
						},
					})
				).to.be.revertedWith('SignatureExpired');
				// .to.be.revertedWithCustomError(
				// 	errorsLib,
				// 	ERRORS.SIGNATURE_EXPIRED
				// );
			});

			it('Testwallet should fail to create curation with sig with invalid nonce', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
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
					nonce + 1,
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
				).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
				// .to.be.revertedWithCustomError(
				// 	errorsLib,
				// 	ERRORS.SIGNATURE_INVALID
				// );
			});

			it('Testwallet should fail to create curation with sig with an unwhitelisted market module', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					fixPriceMarketModule.address,
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
						marketModule: fixPriceMarketModule.address,
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
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			it('Testwallet should fail to create curation with sig with an unwhitelisted minter module', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				await expect(
					bardsHub.connect(governance).whitelistMintModule(emptyMinter.address, false)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					ZERO_ADDRESS,
					mockMarketModuleInitData,
					fixPriceMarketModule.address,
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
						minterMarketModule: fixPriceMarketModule.address,
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
					ERRORS.MINTER_MODULE_NOT_WHITELISTED
				);
			});

			it('TestWallet should sign attempt to create curation with sig, cancel via empty permitForAll, then fail to create curation with sig', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					ZERO_ADDRESS,
					mockMinterMarketModuleInitData,
					mockCurationMetaData,
					nonce,
					MAX_UINT256
				);

				await cancelWithPermitForAll();

				await expect(
					bardsHub.createCurationWithSig({
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
			it('TestWallet should post with sig, fetched curation data should be accurate', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();
				const { v, r, s } = await getCreateCurationWithSigParts(
					FIRST_PROFILE_ID,
					ZERO_ADDRESS,
					0,
					MOCK_PROFILE_CONTENT_URI,
					fixPriceMarketModule.address,
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
						marketModule: fixPriceMarketModule.address,
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

				const pub = await bardsHub.getCuration(FIRST_PROFILE_ID);
				expect(pub.tokenContractPointed).to.eq(ZERO_ADDRESS);
				expect(pub.tokenIdPointed).to.eq(0);
				expect(pub.contentURI).to.eq(MOCK_PROFILE_CONTENT_URI);
				expect(pub.marketModule).to.eq(fixPriceMarketModule.address);
				expect(pub.minterMarketModule).to.eq(ZERO_ADDRESS);
			});
		});

	});
})