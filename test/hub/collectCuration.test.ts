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
	user
} from '../__setup.test';

makeSuiteCleanRoom('Collecting', function () {
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
	});

	context('Generic Stories', function () {
		context('Stories', function () {
			it('Collecting should work if the collector is the curation owner even', async function () {
				await expect(
					bardsCurationToken.mint(userAddress, 1000000)
				).to.not.be.reverted;

				console.log(await bardsCurationToken.balanceOf(userAddress));

				await expect(
					bardsCurationToken.connect(user).approve(fixPriceMarketModule.address, 1000000)
				).to.not.be.reverted;

				// await expect(
				// 	bardsHub.collect({
				// 		collector: userAddress,
				// 		curationId: FIRST_PROFILE_ID + 1,
				// 		curationIds: [],
				// 		allocationIds: [],
				// 		collectMetaData: [],
				// 		fromCuration: false
				// 	})
				// ).to.not.be.reverted;

			});

		});

	});



});