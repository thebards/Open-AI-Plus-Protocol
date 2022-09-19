import { zeroPad } from '@ethersproject/bytes';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { constants, utils, BytesLike, BigNumber, Signature } from 'ethers'
const { AddressZero, MaxUint256 } = constants
import {
	MAX_UINT256,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS,
	MOCK_PROFILE_HANDLE2,
	MAX_NUM
} from '../utils/Constants';
import {
	DataTypes
} from "../../typechain-types/contracts/core/BardsHub";

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
	toBCT,
	getCollectWithSigParts,
	getBCTPermitWithSigParts,
	approveToken
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
	eventsLib,
	cloneMinter
} from '../__setup.test';
import { IERC721Enumerable__factory } from '../../typechain-types';

makeSuiteCleanRoom('Fix Price Market Module', function () {

	beforeEach(async function () {
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
				marketModule: ZERO_ADDRESS,
				marketModuleInitData: mockMarketModuleInitData,
				minterMarketModule: ZERO_ADDRESS,
				minterMarketModuleInitData: mockMinterMarketModuleInitData,
				curationMetaData: mockCurationMetaData
			})
		).to.not.be.reverted;
	});

	context('Negatives Stories', function () {
		it('userTwo should fail to collect without any market module set', async function () {
			const collectMetaData = abiCoder.encode(
				['address', 'uint256'],
				[ZERO_ADDRESS, 1]
			);

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
					marketModuleInitData: mockFreeMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockMinterMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;
			await expect(
				bardsHub.connect(userTwo).collect({
					curationId: FIRST_PROFILE_ID + 1,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				})
			).to.be.revertedWithCustomError(
				errorsLib,
				ERRORS.MARKET_ZERO_ADDRESS
			);
		});

		it('Should fail to collect when buyer and seller are the same.', async function () {
			const mockMarketModuleInitData = abiCoder.encode(
				['address', 'address', 'uint256', 'address', 'address'],
				[ZERO_ADDRESS, bardsCurationToken.address, toBCT(10), ZERO_ADDRESS, transferMinter.address]
			);

			// token 2
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
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;

			const collectMetaData = abiCoder.encode(
				['address', 'uint256', 'address', 'address'],
				[bardsHub.address, FIRST_PROFILE_ID + 1, testWallet.address, testWallet.address]
			);

			await expect(
				bardsHub.connect(testWallet).collect({
					curationId: FIRST_PROFILE_ID + 1,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				})
			).to.be.rejectedWith('Buyer is same with seller.');
		});
		
	});

	context('Stories', function () {
		it('testWallet should collect with clone minter', async function () {
			const mockMarketModuleInitData = abiCoder.encode(
				['address', 'address', 'uint256', 'address', 'address'],
				[ZERO_ADDRESS, bardsCurationToken.address, toBCT(10), ZERO_ADDRESS, cloneMinter.address]
			);

			// tokenId 2
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
					marketModuleInitData: mockFreeMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;

			// token 3
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
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;

			const collectMetaData = abiCoder.encode(
				['uint256', 'address', 'string', 'bytes', 'bytes', 'bytes'],
				[FIRST_PROFILE_ID + 2, testWallet.address, '', mockMarketModuleInitData, mockMarketModuleInitData, mockCurationMetaData]
			);

			await expect(
				bardsHub.connect(governance).whitelistProfileCreator(testWallet.address, true)
			).to.not.be.reverted;

			await expect(
				bardsHub.connect(testWallet).setDefaultProfile(FIRST_PROFILE_ID + 1)
			).to.not.be.reverted;

			await expect(
				bardsCurationToken.mint(testWallet.address, toBCT(100))
			).to.not.be.reverted;

			// Allow to transfer tokens
			await approveToken(fixPriceMarketModule.address, MaxUint256);

			const tokenPair = await collectReturningTokenPair({
				sender: testWallet,
				vars: {
					curationId: FIRST_PROFILE_ID + 2,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				},
			})

			expect(tokenPair[0]).to.eq(bardsHub.address);
			expect(tokenPair[1]).to.eq(toBN(4));
			expect(await bardsHub.ownerOf(4)).to.eq(testWallet.address);
		})

		it('testWallet should collect with transfer minter', async function () {
			const mockMarketModuleInitData = abiCoder.encode(
				['address', 'address', 'uint256', 'address', 'address'],
				[ZERO_ADDRESS, bardsCurationToken.address, toBCT(10), ZERO_ADDRESS, transferMinter.address]
			);

			// token 2
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
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData
				})
			).to.not.be.reverted;

			const collectMetaData = abiCoder.encode(
				['address', 'uint256', 'address', 'address'],
				[bardsHub.address, FIRST_PROFILE_ID + 1, userAddress, testWallet.address]
			);

			await expect(
				bardsHub.setApprovalForAll(transferMinter.address, true)
			).to.not.be.reverted;

			await expect(
				bardsCurationToken.mint(testWallet.address, toBCT(100))
			).to.not.be.reverted;

			// Allow to transfer tokens for testWallet
			await approveToken(fixPriceMarketModule.address, MaxUint256);

			const tokenPair = await collectReturningTokenPair({
				sender: testWallet,
				vars: {
					curationId: FIRST_PROFILE_ID + 1,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				},
			});

			expect(tokenPair[0]).to.eq(bardsHub.address);
			expect(tokenPair[1]).to.eq(toBN(2));
			expect(await bardsHub.ownerOf(FIRST_PROFILE_ID + 1)).to.eq(testWallet.address);
		});
	})

})