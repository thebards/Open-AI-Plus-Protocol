import '@nomiclabs/hardhat-ethers';
import { expect, use } from 'chai';
import { constants, BigNumber } from 'ethers'
import { BigNumber as BN } from 'bignumber.js'
const { AddressZero, MaxUint256, WeiPerEther } = constants
import {
	DEFAULTS,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS,
	FIRST_PROFILE_ID,
	ISSUANCE_RATE_PER_BLOCK,
	MOCK_PROFILE_CONTENT_URI,
	MOCK_PROFILE_HANDLE,
	ZERO_ADDRESS,
} from '../utils/Constants';
import {
	toBCT,
	latestBlock,
	advanceToNextEpoch,
	advanceBlocks,
	toBN,
	formatBCT,
	approveToken,
	waitForTx,
	matchEvent,
	getTimestamp,
} from '../utils/Helpers';
import {
	makeSuiteCleanRoom,
	governance,
	epochManager,
	rewardsManager,
	bardsCurationToken,
	bardsStaking,
	userTwo,
	userTwoAddress,
	userThree,
	userThreeAddress,
	bardsHub,
	userAddress,
	CurationType,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	mockCurationMetaData,
	testWallet,
	user,
	abiCoder,
	governanceAddress
} from '../__setup.test';

const toRound = (n: BigNumber) => formatBCT(n).split('.')[0]

makeSuiteCleanRoom('Reward Manager', function () {
	const testTokens = toBCT('1000000')
	const ISSUANCE_RATE_PERIODS = 4 // blocks required to issue 5% rewards
	const ISSUANCE_RATE_PER_BLOCK = toBN('1012272234429039270') // % increase every block

	// Core formula that gets accumulated rewards per staking for a period of time
	const getRewardsPerStaking = (p: BN, r: BN, t: BN, s: BN): string => {
		if (s.eq(0)) {
			return '0'
		}
		return p.times(r.pow(t)).minus(p).div(s).toPrecision(18).toString()
	}

	// Tracks the accumulated rewards as totalSignalled or supply changes across snapshots
	class RewardsTracker {
		totalSupply = BigNumber.from(0)
		totalStaked = BigNumber.from(0)
		lastUpdatedBlock = BigNumber.from(0)
		accumulated = BigNumber.from(0)

		static async create() {
			const tracker = new RewardsTracker()
			await tracker.snapshot()
			return tracker
		}

		async snapshot() {
			this.accumulated = this.accumulated.add(await this.accrued())
			this.totalSupply = await bardsCurationToken.totalSupply()
			this.totalStaked = await bardsStaking.getTotalStakingToken()
			this.lastUpdatedBlock = await latestBlock()
			return this
		}

		async elapsedBlocks() {
			const currentBlock = await latestBlock()
			return currentBlock.sub(this.lastUpdatedBlock)
		}

		async accrued() {
			const nBlocks = await this.elapsedBlocks()
			const n = getRewardsPerStaking(
				new BN(this.totalSupply.toString()),
				new BN(ISSUANCE_RATE_PER_BLOCK.toString()).div(1e18),
				new BN(nBlocks.toString()),
				new BN(this.totalStaked.toString()),
			)
			return toBCT(n)
		}
	}

	// Test accumulated rewards per signal
	const shouldGetNewRewardsPerStaking = async (nBlocks = ISSUANCE_RATE_PERIODS) => {
		// -- t0 --
		const tracker = await RewardsTracker.create()

		// Jump
		await advanceBlocks(nBlocks)

		// -- t1 --

		// Contract calculation
		const contractAccrued = await rewardsManager.getNewRewardsPerStaking()
		// Local calculation
		const expectedAccrued = await tracker.accrued()

		// Check
		expect(toRound(expectedAccrued)).eq(toRound(contractAccrued))
		return expectedAccrued
	}
	
	context('configuration', () => {
		context('setting issuance rate', function () {
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
			await bardsCurationToken.connect(governance).transfer(userTwoAddress, testTokens)
			await approveToken(bardsStaking.address, MaxUint256);
			await bardsCurationToken.connect(userTwo).approve(bardsStaking.address, MaxUint256);
		})

		context('getNewRewardsPerStaking', function () {
			it('accrued per staking when no tokens staked', async function () {
				// When there is no tokens staked no rewards are accrued
				await advanceToNextEpoch(epochManager)
				const accrued = await rewardsManager.getNewRewardsPerStaking()
				expect(accrued).eq(0)
			})

			it('accrued per signal when tokens signalled', async function () {
				// Update total signalled
				const tokensToStaking = toBCT('1000')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToStaking)

				// Check
				await shouldGetNewRewardsPerStaking()
			})

			it('accrued per staking when staked tokens w/ many curations', async function () {
				// Update total signalled
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, toBCT('1000'))

				// Check
				await shouldGetNewRewardsPerStaking()

				// Update total signalled
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID + 1, toBCT('250'))

				// Check
				await shouldGetNewRewardsPerStaking()
			})
		});

		context('updateAccRewardsPerStaking', function () {
			it('update the accumulated rewards per staking state', async function () {
				// Update total signalled
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, toBCT('1000'))
				// Snapshot
				const tracker = await RewardsTracker.create()

				// Update
				await rewardsManager.updateAccRewardsPerStaking()
				const contractAccrued = await rewardsManager.accRewardsPerStaking()

				// Check
				const expectedAccrued = await tracker.accrued()
				expect(toRound(expectedAccrued)).eq(toRound(contractAccrued))
			})

			it('update the accumulated rewards per staking state after many blocks', async function () {
				// Update total signalled
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, toBCT('1000'))
				// Snapshot
				const tracker = await RewardsTracker.create()

				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Update
				await rewardsManager.updateAccRewardsPerStaking()
				const contractAccrued = await rewardsManager.accRewardsPerStaking()

				// Check
				const expectedAccrued = await tracker.accrued()
				expect(toRound(expectedAccrued)).eq(toRound(contractAccrued))
			})
		})

		context('getAccRewardsForCuration', function () {
			it('accrued for each curation', async function () {
				// Curator1 - Update total staked
				const stake1 = toBCT('1500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, stake1)
				const tracker1 = await RewardsTracker.create()

				// Curator2 - Update total staked
				const stake2 = toBCT('500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID + 1, stake2)

				// Snapshot
				const tracker2 = await RewardsTracker.create()
				await tracker1.snapshot()

				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Snapshot
				await tracker1.snapshot()
				await tracker2.snapshot()

				// Calculate rewards
				const rewardsPerStaking1 = await tracker1.accumulated
				const rewardsPerStaking2 = await tracker2.accumulated
				const expectedRewardsSG1 = rewardsPerStaking1.mul(stake1).div(WeiPerEther)
				const expectedRewardsSG2 = rewardsPerStaking2.mul(stake2).div(WeiPerEther)

				// Get rewards from contract
				const contractRewardsSG1 = await rewardsManager.getAccRewardsForCuration(
					FIRST_PROFILE_ID,
				)
				const contractRewardsSG2 = await rewardsManager.getAccRewardsForCuration(
					FIRST_PROFILE_ID + 1,
				)

				// Check
				expect(toRound(expectedRewardsSG1)).eq(toRound(contractRewardsSG1))
				expect(toRound(expectedRewardsSG2)).eq(toRound(contractRewardsSG2))
			})
		})

		context('onCurationStakingUpdate', function () {
			it('update the accumulated rewards for curation state', async function () {
				// Update total staked
				const stake1 = toBCT('1500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, stake1)
				// Snapshot
				const tracker1 = await RewardsTracker.create()

				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Update
				await rewardsManager.onCurationStakingUpdate(FIRST_PROFILE_ID)

				// Check
				const contractRewardsSG1 = await rewardsManager.getAccRewardsForCuration(FIRST_PROFILE_ID)
				const rewardsPerStake1 = await tracker1.accrued()
				const expectedRewardsSG1 = rewardsPerStake1.mul(stake1).div(WeiPerEther)
				expect(toRound(expectedRewardsSG1)).eq(toRound(contractRewardsSG1))

				const contractAccrued = await rewardsManager.accRewardsPerStaking()
				const expectedAccrued = await tracker1.accrued()
				expect(toRound(expectedAccrued)).eq(toRound(contractAccrued))

				const contractBlockUpdated = await rewardsManager.accRewardsPerStakingLastBlockUpdated()
				const expectedBlockUpdated = await latestBlock()
				expect(expectedBlockUpdated).eq(contractBlockUpdated)
			})
		})

		context('getAccRewardsPerAllocatedToken', function () {
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
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;
			})
			it('accrued per allocated token', async function () {
				// Staking
				const tokensToAllocate = toBCT('12500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToAllocate)
				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Check
				const cr1 = await rewardsManager.curationRewards(FIRST_PROFILE_ID)
				// We trust this function because it was individually tested in previous test
				const accRewardsForCuration1 = await rewardsManager.getAccRewardsForCuration(FIRST_PROFILE_ID)
				const accruedRewards1 = accRewardsForCuration1.sub(cr1.accRewardsForCurationSnapshot)
				const expectedRewardsAT1 = accruedRewards1.mul(WeiPerEther).div(tokensToAllocate)

				const contractRewardsAT1 = (
					await rewardsManager.getAccRewardsPerAllocatedToken(FIRST_PROFILE_ID)
				)[0]
				expect(expectedRewardsAT1).eq(contractRewardsAT1)
			})
		})

		context('onCurationAllocationUpdate', function () {
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
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;
			})
			it('update the accumulated rewards for allocated tokens state', async function () {
				// Staking
				const tokensToAllocate = toBCT('12500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToAllocate)

				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Prepare expected results
				// NOTE: calculated the expected result manually as the above code has 1 off block difference
				// replace with a RewardsManagerMock
				const expectedCurationRewards = toBCT('628858461')
				const expectedRewardsAT = toBCT('50308')

				// Update
				await rewardsManager.onCurationAllocationUpdate(FIRST_PROFILE_ID)

				// Check on demand results saved
				const curationRewards = await rewardsManager.curationRewards(FIRST_PROFILE_ID)
				const contractCurationRewards = await rewardsManager.getAccRewardsForCuration(
					FIRST_PROFILE_ID,
				)
				const contractRewardsAT = curationRewards.accRewardsPerAllocatedToken

				expect(toRound(expectedCurationRewards)).eq(toRound(contractCurationRewards))
				expect(toRound(expectedRewardsAT)).eq(toRound(contractRewardsAT))
			})
		})

		context('getRewards', function () {
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
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;
			})

			it('calculate rewards using the curation staked + allocated tokens', async function () {
				// Staking
				const tokensToAllocate = toBCT('12500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToAllocate)

				// Jump
				await advanceBlocks(ISSUANCE_RATE_PERIODS)

				// Rewards
				const contractRewards = await rewardsManager.getRewards(await bardsHub.getAllocationIdById(FIRST_PROFILE_ID))

				// We trust using this function in the test because we tested it
				// standalone in a previous test
				const contractRewardsAT1 = (
					await rewardsManager.getAccRewardsPerAllocatedToken(FIRST_PROFILE_ID)
				)[0]

				const expectedRewards = contractRewardsAT1.mul(tokensToAllocate).div(WeiPerEther)

				expect(expectedRewards).eq(contractRewards)
			})
		})

		context('takeRewards', function () {
			
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
						curationMetaData: mockCurationMetaData,
						curationFrom: 0,
					})
				).to.not.be.reverted;
				
				bardsCurationToken.connect(governance).addMinter(rewardsManager.address)
			})
			async function setupCurationStaking() {
				// Setup
				await epochManager.connect(governance).setEpochLength(10)
				// await rewardsManager.connect(governance).setIssuanceRate(DEFAULTS.rewards.issuanceRate)
				// Staking
				const tokensTostake = toBCT('12500')
				await bardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensTostake)
			}

			it('should distribute rewards on closed allocation and stake', async function () {
				// Setup
				await setupCurationStaking()

				// Jump
				await advanceBlocks(await epochManager.epochLength())

				// Before state
				const beforeTokenSupply = await bardsCurationToken.totalSupply()
				const beforeCurationTokensStaked = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
				const beforeCuratorBalance = await bardsCurationToken.balanceOf(userTwoAddress)
				const beforeStakingBalance = await bardsCurationToken.balanceOf(testWallet.address)

				const expectedCurationRewards = toBCT('1435905882')

				// Close allocation. At this point rewards should be collected for that indexer
				const receipt = await waitForTx(
					bardsStaking
						.connect(user)
						.closeAllocation(
							await bardsHub.getAllocationIdById(FIRST_PROFILE_ID), 
							FIRST_PROFILE_ID
						)
				)

				matchEvent(receipt, 'AllocationClosed', [
					FIRST_PROFILE_ID,
					await epochManager.currentEpoch(),
					await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID),
					await bardsHub.getAllocationIdById(FIRST_PROFILE_ID),
					(await bardsStaking.getSimpleAllocation(await bardsHub.getAllocationIdById(FIRST_PROFILE_ID))).effectiveAllocationStake,
					userAddress,
					FIRST_PROFILE_ID,
					true,
					await getTimestamp(),
				]);

				// After state
				const afterTokenSupply = await bardsCurationToken.totalSupply()
				const afterCurationTokensStaked = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
				const afterCuratorBalance = await bardsCurationToken.balanceOf(userTwoAddress)
				const afterStakingBalance = await bardsCurationToken.balanceOf(testWallet.address)

				// Check that rewards are put into curator stake
				const expectedCurationStake = beforeCurationTokensStaked.add(expectedCurationRewards)
				const expectedTokenSupply = beforeTokenSupply.add(expectedCurationRewards)

				// Check stake should have increased with the rewards staked
				expect(toRound(afterCurationTokensStaked)).eq(toRound(expectedCurationStake))
				// Check curator balance remains the same
				expect(afterCuratorBalance).eq(beforeCuratorBalance)
				// Check rewards are kept in the staking contract
				expect(toRound(afterStakingBalance)).eq(
					toRound(beforeStakingBalance.add(expectedCurationRewards)),
				)
				// Check that tokens have been minted
				expect(toRound(afterTokenSupply)).eq(toRound(expectedTokenSupply))
			})

			it('should distribute rewards on closed allocation and send to destinations', async function () {
				// Setup
				await setupCurationStaking()
				await epochManager.connect(governance).setEpochLength(DEFAULTS.epochs.lengthInBlocks)
				// Jump
				await advanceBlocks(await epochManager.epochLength())

				// Before state
				const beforeUserBalance = await bardsCurationToken.balanceOf(userAddress)
				const beforeUserThreeBalance = await bardsCurationToken.balanceOf(userThreeAddress)

				// Before state
				const beforeTokenSupply = await bardsCurationToken.totalSupply()
				const beforeCurationTokensStaked = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
				const beforeStakingBalance = await bardsCurationToken.balanceOf(testWallet.address)

				const expectedCurationRewards = toBCT('11302674700')

				const mockCurationMetaData = abiCoder.encode(
					['address[]', 'uint256[]', 'uint32[]', 'uint32[]', 'uint32', 'uint32'],
					[[userAddress, userThreeAddress], [], [800000, 200000], [], DEFAULT_CURATION_BPS, DEFAULT_STAKING_BPS]
				);

				// Close allocation. At this point rewards should be collected for that indexer
				await expect(
					bardsHub
						.connect(user)
						.updateCuration({
							tokenId: FIRST_PROFILE_ID,
							curationData: mockCurationMetaData
						})
				).to.not.be.reverted;

				// After state

				const afterTokenSupply = await bardsCurationToken.totalSupply()
				const afterCurationTokensStaked = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
				const afterStakingBalance = await bardsCurationToken.balanceOf(testWallet.address)

				// Check that rewards are put into curator stake
				const expectedCurationStake = beforeCurationTokensStaked.add(expectedCurationRewards)
				const expectedTokenSupply = beforeTokenSupply.add(expectedCurationRewards)

				// Check stake should have increased with the rewards staked
				expect(toRound(afterCurationTokensStaked)).eq(toRound(expectedCurationStake))
				// Check rewards are kept in the staking contract
				expect(toRound(afterStakingBalance)).eq(
					toRound(beforeStakingBalance.add(expectedCurationRewards)),
				)
				// Check that tokens have been minted
				expect(toRound(afterTokenSupply)).eq(toRound(expectedTokenSupply))

				// Jump
				await advanceBlocks(await epochManager.epochLength())

				await expect(
					bardsStaking.connect(user).closeAllocation(2, 0)
				).to.not.be.reverted;

				const afterUserBalance = await bardsCurationToken.balanceOf(userAddress)
				const afterUserThreeBalance = await bardsCurationToken.balanceOf(userThreeAddress)

				const expectNewRewards = toBCT('23527550282');
				expect(toRound(afterUserBalance)).eq(toRound(beforeUserBalance.add(expectNewRewards.mul(8).div(10))))
				expect(toRound(afterUserThreeBalance)).eq(toRound(beforeUserThreeBalance.add(expectNewRewards.mul(2).div(10))))
			})

			it('should deny rewards if curation on denylist', async function () {
				// Setup
				await rewardsManager.connect(governance).setDenied(FIRST_PROFILE_ID, true)
				await setupCurationStaking()

				// Jump
				await advanceBlocks(await epochManager.epochLength())

				// Close allocation. At this point rewards should be collected for that indexer
				const receipt = await waitForTx(
					bardsStaking
						.connect(user)
						.closeAllocation(
							await bardsHub.getAllocationIdById(FIRST_PROFILE_ID),
							FIRST_PROFILE_ID
						)
				)

				matchEvent(receipt, 'AllocationClosed', [
					FIRST_PROFILE_ID,
					await epochManager.currentEpoch(),
					await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID),
					await bardsHub.getAllocationIdById(FIRST_PROFILE_ID),
					(await bardsStaking.getSimpleAllocation(await bardsHub.getAllocationIdById(FIRST_PROFILE_ID))).effectiveAllocationStake,
					userAddress,
					FIRST_PROFILE_ID,
					true,
					await getTimestamp(),
				]);
			})
		})
	});

})