import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	MOCK_PROFILE_HANDLE2
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	collectReturningTokenPair,
	toBN,
} from '../utils/Helpers';
import {
	abiCoder,
	bardsHub,
	CurationType,
	makeSuiteCleanRoom,
	governance,
	userTwoAddress,
	userTwo,
	userAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockFreeMarketModuleInitData,
	mockMinterMarketModuleInitData,
	errorsLib,
	transferMinter,
	freeMarketModule,
	cloneMinter
} from '../__setup.test';

makeSuiteCleanRoom('Free Market Module', function () {

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
				curationMetaData: mockCurationMetaData,
				curationFrom: 0,
			})
		).to.not.be.reverted;
	});

	context('Negatives Stories', function () {
		it('UserTwo should fail to collect without any market module set', async function () {
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
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
	});

	context('Stories', function () {
		it('UserTwo should collect with clone minter', async function () {
			const mockFreeMarketModuleInitData = abiCoder.encode(
				['address', 'address'],
				[ZERO_ADDRESS, cloneMinter.address]
			);

			// tokenId 2
			await expect(
				bardsHub.connect(userTwo).createProfile({
					to: userTwoAddress,
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
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
					marketModule: freeMarketModule.address,
					marketModuleInitData: mockFreeMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;

			const collectMetaData = abiCoder.encode(
				['uint256', 'address', 'string', 'bytes', 'bytes', 'bytes'],
				[FIRST_PROFILE_ID + 2, userTwoAddress, '', mockFreeMarketModuleInitData, mockFreeMarketModuleInitData, mockCurationMetaData]
			);

			await expect(
				bardsHub.connect(governance).whitelistProfileCreator(userTwoAddress, true)
			).to.not.be.reverted;

			await expect(
				bardsHub.connect(userTwo).setDefaultProfile(FIRST_PROFILE_ID + 1)
			).to.not.be.reverted;

			const tokenPair = await collectReturningTokenPair({
				sender: userTwo,
				vars: {
					curationId: FIRST_PROFILE_ID + 2,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				},
			})

			expect(tokenPair[0]).to.eq(bardsHub.address);
			expect(tokenPair[1]).to.eq(toBN(4));
			expect(await bardsHub.ownerOf(4)).to.eq(userTwoAddress);
			
		})

		it('UserTwo should collect with transfer minter', async function () {
			const mockFreeMarketModuleInitData = abiCoder.encode(
				['address', 'address'],
				[ZERO_ADDRESS, transferMinter.address]
			);
			// tokenId 2
			await expect(
				bardsHub.connect(userTwo).createProfile({
					to: userTwoAddress,
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
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
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
					marketModule: freeMarketModule.address,
					marketModuleInitData: mockFreeMarketModuleInitData,
					minterMarketModule: ZERO_ADDRESS,
					minterMarketModuleInitData: mockFreeMarketModuleInitData,
					curationMetaData: mockCurationMetaData,
					curationFrom: 0,
				})
			).to.not.be.reverted;

			const collectMetaData = abiCoder.encode(
				['address', 'uint256', 'address', 'address'],
				[bardsHub.address, FIRST_PROFILE_ID + 2, userAddress, userTwoAddress]
			);

			await expect(
				bardsHub.setApprovalForAll(transferMinter.address, true)
			).to.not.be.reverted;

			const tokenPair = await collectReturningTokenPair({
				sender: userTwo,
				vars: {
					curationId: FIRST_PROFILE_ID + 2,
					curationIds: [],
					collectMetaData: collectMetaData,
					fromCuration: false
				},
			});

			expect(tokenPair[0]).to.eq(bardsHub.address);
			expect(tokenPair[1]).to.eq(toBN(3));
			expect(await bardsHub.ownerOf(FIRST_PROFILE_ID + 2)).to.eq(userTwoAddress);
		});
	})

})