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
	DEFAULTS,
	ISSUANCE_RATE_PER_BLOCK,
	ISSUANCE_RATE_PERIODS
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	cancelWithPermitForAll,
	getSetMarketModuleWithSigParts,
	getSetCurationContentURIWithSigParts,
	getCreateCurationWithSigParts,
	deriveChannelKey,
	toBCT,
	getBCTPermitWithSigParts,
	toBN,
	getTimestamp,
	latestBlock,
	advanceBlockTo,
	advanceToNextEpoch,
	advanceBlock
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
	user,
	epochManager,
	eventsLib,
	rewardsManager
} from '../__setup.test';

makeSuiteCleanRoom('Reward Manager', function () {
	context('configuration', () => {
		context('issuance rate update', function () {
			it('reject set issuance rate if unauthorized', async function () {
				await expect(
					rewardsManager.setIssuanceRate(toBCT('1.025'))
				).to.be.revertedWith('Only governance can call')
			})

			it('reject set issuance rate to less than minimum allowed', async function () {
				await expect(
					rewardsManager.connect(governance).setIssuanceRate(toBCT('0.1'))
				).to.be.revertedWith('Issuance rate under minimum allowed')
			})

			it('should set issuance rate to minimum allowed', async function () {
				const newIssuanceRate = toBCT('1') // this get a bignumber with 1e18
				await rewardsManager.connect(governance).setIssuanceRate(toBCT('1'));
				expect(await rewardsManager.issuanceRate()).eq(newIssuanceRate)
			})

			it('should set issuance rate', async function () {
				const newIssuanceRate = toBCT('1.025')
				await rewardsManager.connect(governance).setIssuanceRate(newIssuanceRate)
				expect(await rewardsManager.issuanceRate()).eq(newIssuanceRate)
				expect(await rewardsManager.accRewardsPerStakingLastBlockUpdated()).eq(await latestBlock())
			})
		});
	});

	context('issuing rewards', async function () {
		beforeEach(async function () {
			// 5% minute rate (4 blocks)
			await rewardsManager.connect(governance).setIssuanceRate(ISSUANCE_RATE_PER_BLOCK)
		})

		context('getNewRewardsPerStaking', function () {
			it('accrued per staking when no tokens staked', async function () {
				// When there is no tokens staked no rewards are accrued
				await advanceToNextEpoch(epochManager)
				const accrued = await rewardsManager.getNewRewardsPerStaking()
				expect(accrued).eq(0)
			})
		});
	});

})