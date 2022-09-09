import { zeroPad } from '@ethersproject/bytes';
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
	getSetMarketModuleWithSigParts
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

makeSuiteCleanRoom('Setting Market Module', function () {
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
		});

		context('Negatives Stories', function () {
			it('UserTwo should fail to set the market module for the curation owned by User', async function () {
				await expect(
					bardsHub.connect(userTwo).setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_OWNER_OR_APPROVED
				);

				await expect(
					bardsHub.connect(userTwo).setMinterMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.NOT_OWNER_OR_APPROVED
				);
			});

			it('User should fail to set market modules that is not whitelisted', async function () {
				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: userAddress,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);

				await expect(
					bardsHub.setMinterMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: userAddress,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			it('User should fail to set market modules with invalid market module data format', async function () {
				const faultMarketModuleInitData = abiCoder.encode(
					['address', 'uint256', 'address', 'address'],
					[ZERO_ADDRESS, 0, ZERO_ADDRESS, ZERO_ADDRESS]
				);

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: faultMarketModuleInitData
					})
				).to.be.revertedWithoutReason;

				await expect(
					bardsHub.setMinterMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: faultMarketModuleInitData
					})
				).to.be.revertedWithoutReason;
			});
		});

		context('Stories', function () {
			it('User should set a whitelisted market modules, fetching the profile follow module should return the correct address, user then sets it to the zero address and fetching returns the zero address', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.not.be.reverted;

				expect(await bardsHub.getMarketModule(FIRST_PROFILE_ID)).to.eq(fixPriceMarketModule.address);

				await expect(
					bardsHub.setMarketModule({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: ZERO_ADDRESS,
						marketModuleInitData: mockMarketModuleInitData
					})
				).to.not.be.reverted;

				expect(await bardsHub.getMarketModule(FIRST_PROFILE_ID)).to.eq(ZERO_ADDRESS);
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
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
		});

		context('Negatives Stories', function () {
			it('TestWallet should fail to set a market module with sig with signature deadline mismatch', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce,
					'0'
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
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
					ERRORS.SIGNATURE_INVALID
				);
			});

			it('TestWallet should fail to set a market module with sig with invalid deadline', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce,
					'0'
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						sig: {
							v,
							r,
							s,
							deadline: '0',
						},
					})
				).to.be.revertedWithCustomError(
					errorsLib,
					ERRORS.SIGNATURE_EXPIRED
				);
			});

			it('TestWallet should fail to set a market module with sig with invalid nonce', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce + 1,
					MAX_UINT256
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
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
					ERRORS.SIGNATURE_INVALID
				);
			});

			it('TestWallet should fail to set a market module with sig with an unwhitelisted follow module', async function () {
				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
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
					ERRORS.MARKET_MODULE_NOT_WHITELISTED
				);
			});

			it('TestWallet should sign attempt to set market module with sig, then cancel with empty permitForAll, then fail to set market module with sig', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce,
					MAX_UINT256
				);

				await cancelWithPermitForAll();

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
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
					ERRORS.SIGNATURE_INVALID
				);
			});
		});

		context('Stories', function () {
			it('TestWallet should set a whitelisted market module with sig, fetching the market module should return the correct address', async function () {
				await expect(
					bardsHub.connect(governance).whitelistMarketModule(fixPriceMarketModule.address, true)
				).to.not.be.reverted;

				const nonce = (await bardsHub.sigNonces(testWallet.address)).toNumber();

				const { v, r, s } = await getSetMarketModuleWithSigParts(
					FIRST_PROFILE_ID,
					bardsHub.address,
					FIRST_PROFILE_ID,
					fixPriceMarketModule.address,
					mockMarketModuleInitData,
					nonce,
					MAX_UINT256
				);

				await expect(
					bardsHub.setMarketModuleWithSig({
						curationId: FIRST_PROFILE_ID,
						tokenContract: bardsHub.address,
						tokenId: FIRST_PROFILE_ID,
						marketModule: fixPriceMarketModule.address,
						marketModuleInitData: mockMarketModuleInitData,
						sig: {
							v,
							r,
							s,
							deadline: MAX_UINT256,
						},
					})
				).to.not.be.reverted;

				expect(await bardsHub.getMarketModule(FIRST_PROFILE_ID)).to.eq(fixPriceMarketModule.address);
			});
		});
	});
});