import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { randomBytes, randomInt, randomUUID } from 'crypto';
import { Address } from 'defender-relay-client';
import { constants, utils, BytesLike, BigNumber, Signature, Event } from 'ethers'
import { BardsStaking, BardsStaking__factory, MockRebatePool, MockRebatePool__factory } from '../../build/types';
const { AddressZero, MaxUint256 } = constants
import {
	MAX_UINT256,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	DEFAULTS,
	BPS_MAX,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	toBCT,
	toBN,
	getTimestamp,
	randomAddress,
	approveToken,
	waitForTx,
	matchEvent,
	calcBondingCurve,
	chunkify,
	stakingReturningPair,
	unstakingReturningPair,
	toFloat,
	toRound,
	cobbDouglas,
	toFixed
} from '../utils/Helpers';

import {
	bardsHub,
	testWallet,
	governance,
	userTwoAddress,
	userTwo,
	bardsCurationToken,
	epochManager,
	bardsShareToken,
	bardsStakingLibs,
	deployer,
	bancorFormula,
	userAddress,
	CurationType,
	mockMarketModuleInitData,
	mockCurationMetaData,
	errorsLib,
	bardsStaking
} from '../__setup.test';

context('Bards Staking', () => {
	const testTokens = toBCT('10000000000')
	const tokensToStake = toBCT('100')
	let thisBardsStaking: BardsStaking;
	const shareof100token = toBN('3162277660168379331');

	const shouldStake = async (_tokensToStake: BigNumber, _expectedShare: BigNumber) => {
		// Before state
		const beforeTokenTotalSupply = await bardsCurationToken.totalSupply()
		const beforeStakingTokens = await bardsCurationToken.balanceOf(userTwoAddress)
		const beforeStakingShare = await thisBardsStaking.getDelegatorShare(
			userTwoAddress,
			FIRST_PROFILE_ID
		);

		const beforePoolShare = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
		const beforePoolTokens = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const beforeTotalTokens = await bardsCurationToken.balanceOf(testWallet.address)

		// Calculations
		const stakingTaxPercentage = await thisBardsStaking.stakingTaxPercentage()
		const stakingTax = _tokensToStake.mul(toBN(stakingTaxPercentage)).div(toBN(BPS_MAX))

		// staking
		const receipt = await waitForTx(thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, _tokensToStake))

		matchEvent(
			receipt,
			'CurationPoolStaked',
			[
				userTwoAddress,
				FIRST_PROFILE_ID,
				_tokensToStake,
				_expectedShare,
				stakingTax,
				await getTimestamp()
			]
		);

		// After state
		const afterTokenTotalSupply = await bardsCurationToken.totalSupply()
		const afterStakingTokens = await bardsCurationToken.balanceOf(userTwoAddress)
		const afterStakingShare = await thisBardsStaking.getDelegatorShare(
			userTwoAddress,
			FIRST_PROFILE_ID
		);

		const afterPoolShare = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
		const afterPoolTokens = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const afterTotalTokens = await bardsCurationToken.balanceOf(testWallet.address)

		// Curator balance updated
		expect(afterStakingTokens).eq(beforeStakingTokens.sub(_tokensToStake))
		expect(afterStakingShare).eq(beforeStakingShare.add(_expectedShare))
		// Allocated and balance updated
		expect(afterPoolTokens).eq(beforePoolTokens.add(_tokensToStake.sub(stakingTax)))
		expect(afterPoolShare).eq(beforePoolShare.add(_expectedShare))

		expect(await thisBardsStaking.getReserveRatioOfCuration(FIRST_PROFILE_ID)).eq(await thisBardsStaking.defaultStakingReserveRatio())
		// Contract balance updated
		expect(afterTotalTokens).eq(beforeTotalTokens.add(_tokensToStake.sub(stakingTax)))
		// Total supply is reduced to curation tax burning
		expect(afterTokenTotalSupply).eq(beforeTokenTotalSupply.sub(stakingTax))
	}

	const shouldUnstake = async (_shareToRedeem: BigNumber, _expectedTokens: BigNumber) => {
		// Before balances
		const beforeTokenTotalSupply = await bardsCurationToken.totalSupply()
		const beforeStakingShare = await thisBardsStaking.getDelegatorShare(
			userTwoAddress,
			FIRST_PROFILE_ID
		);

		const beforePoolShare = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
		const beforePoolTokens = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const beforeTotalTokens = await bardsCurationToken.balanceOf(testWallet.address)

		// Redeem
		const receipt = await waitForTx(thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, _shareToRedeem))

		matchEvent(
			receipt,
			'StakeDelegatedLocked',
			[
				userTwoAddress,
				FIRST_PROFILE_ID,
				_shareToRedeem,
				_expectedTokens,
				(await epochManager.currentEpoch()).add(DEFAULTS.staking.thawingPeriod),
				await getTimestamp()
			]
		);

		// After state
		const afterTokenTotalSupply = await bardsCurationToken.totalSupply()
		const afterStakingShare = await thisBardsStaking.getDelegatorShare(
			userTwoAddress,
			FIRST_PROFILE_ID
		);

		const afterPoolShare = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
		const afterPoolTokens = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const afterTotalTokens = await bardsCurationToken.balanceOf(testWallet.address)

		// Curator balance updated
		expect(afterStakingShare).eq(beforeStakingShare.sub(_shareToRedeem))
		// Contract balance updated
		expect(afterPoolTokens).eq(beforePoolTokens.sub(_expectedTokens))
		expect(afterPoolShare).eq(beforePoolShare.sub(_shareToRedeem))
		// // Contract balance updated
		expect(afterTotalTokens).eq(beforeTotalTokens)
		// // Total supply is conserved
		expect(afterTokenTotalSupply).eq(beforeTokenTotalSupply)
	}

	const shouldCollect = async (tokensToCollect: BigNumber) => {
		const allocationId = await bardsHub.getAllocationIdById(FIRST_PROFILE_ID)
		// console.log(allocationId);
		// console.log(await bardsStaking.getSimpleAllocation(allocationId))

		// Before state
		const beforeToken = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const beforeFees = await bardsStaking.getFeesCollectedInAllocation(allocationId, bardsCurationToken.address)

		const receipt = await waitForTx(
			bardsStaking.connect(userTwo).collect(
				bardsCurationToken.address, 
				tokensToCollect,
				allocationId
			)
		)
		
		matchEvent(
			receipt,
			'AllocationCollected',
			[
				FIRST_PROFILE_ID,
				await epochManager.currentEpoch(),
				tokensToCollect,
				allocationId,
				userTwoAddress,
				bardsCurationToken.address,
				await getTimestamp()
			]
		);

		// After state
		const afterToken = await bardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
		const afterFees = await bardsStaking.getFeesCollectedInAllocation(allocationId, bardsCurationToken.address)

		// State updatced
		expect(beforeToken).eq(afterToken)
		expect(afterFees).eq(beforeFees.add(tokensToCollect))
	}

	let mockRebatePool: MockRebatePool;

	type RebateRatio = number[]

	interface RebateTestCase {
		totalRewards: number
		fees: number
		totalFees: number
		stake: number
		totalStake: number
	}

	const testCases: RebateTestCase[] = [
		{ totalRewards: 1400, fees: 100, totalFees: 1400, stake: 5000, totalStake: 7300 },
		{ totalRewards: 1400, fees: 300, totalFees: 1400, stake: 600, totalStake: 7300 },
		{ totalRewards: 1400, fees: 1000, totalFees: 1400, stake: 500, totalStake: 7300 },
		{ totalRewards: 1400, fees: 0, totalFees: 1400, stake: 1200, totalStake: 7300 },
	]

	// Edge case #1 - No closed allocations any trade fees
	const edgeCases1: RebateTestCase[] = [
		{ totalRewards: 0, fees: 0, totalFees: 0, stake: 5000, totalStake: 7300 },
		{ totalRewards: 0, fees: 0, totalFees: 0, stake: 600, totalStake: 7300 },
		{ totalRewards: 0, fees: 0, totalFees: 0, stake: 500, totalStake: 7300 },
		{ totalRewards: 0, fees: 0, totalFees: 0, stake: 1200, totalStake: 7300 },
	]

	async function redeem(currency: string, fees: BigNumber, stake: BigNumber): Promise<BigNumber> {
		return await mockRebatePool.callStatic.pop(currency, fees, stake)
	}

	async function shouldMatchOut(testCases: RebateTestCase[], alpha: RebateRatio) {
		const [alphaNumerator, alphaDenominator] = alpha
		await mockRebatePool.setRebateRatio(alphaNumerator, alphaDenominator)

		let totalFees = toBN(0)
		for (const testCase of testCases) {
			totalFees = totalFees.add(toBCT(testCase.fees))
			await mockRebatePool.add(bardsCurationToken.address, toBCT(testCase.fees), toBCT(testCase.stake))
		}

		for (const testCase of testCases) {
			const unclaimedFees = await mockRebatePool.getUnclaimedRewards(bardsCurationToken.address)
			const rewards = await redeem(bardsCurationToken.address, toBCT(testCase.fees), toBCT(testCase.stake))
			let expectedOut = await mockRebatePool.cobbDouglas(
				toBCT(testCase.totalRewards),
				toBCT(testCase.fees),
				toBCT(testCase.totalFees),
				toBCT(testCase.stake),
				toBCT(testCase.totalStake),
				alphaNumerator,
				alphaDenominator,
			)
			if (expectedOut.gt(unclaimedFees)) {
				expectedOut = unclaimedFees
			}
			expect(rewards).eq(expectedOut)
		}
	}

	async function testAlphas(fn, testCases) {
		// Typical alpha
		it('alpha 0.90', async function () {
			const alpha: RebateRatio = [90, 100]
			await fn(testCases, alpha)
		})

		// Typical alpha
		it('alpha 0.25', async function () {
			const alpha: RebateRatio = [1, 4]
			await fn(testCases, alpha)
		})

		// Periodic alpha
		it('alpha 0.33~', async function () {
			const alpha: RebateRatio = [1, 3]
			await fn(testCases, alpha)
		})

		// Small alpha
		it('alpha 0.005', async function () {
			const alpha: RebateRatio = [1, 200]
			await fn(testCases, alpha)
		})

		// Edge alpha
		it('alpha 1', async function () {
			const alpha: RebateRatio = [1, 1]
			await fn(testCases, alpha)
		})
	}

	// Test if the Solidity implementation of the rebate formula match the local implementation
	async function shouldMatchFormulas(testCases: RebateTestCase[], alpha: RebateRatio) {
		const [alphaNumerator, alphaDenominator] = alpha

		for (const testCase of testCases) {
			// Test Typescript cobb-doubglas formula implementation
			const r1 = cobbDouglas(
				testCase.totalRewards,
				testCase.fees,
				testCase.totalFees,
				testCase.stake,
				testCase.totalStake,
				alphaNumerator,
				alphaDenominator,
			)
			// Convert non-alpha values to wei before sending for precision
			const r2 = await mockRebatePool.cobbDouglas(
				toBCT(testCase.totalRewards),
				toBCT(testCase.fees),
				toBCT(testCase.totalFees),
				toBCT(testCase.stake),
				toBCT(testCase.totalStake),
				alphaNumerator,
				alphaDenominator,
			)

			// Must match : contracts to local implementation
			expect(toFixed(r1)).eq(toFixed(r2))
		}
	}

	// Test if the fees deposited into the rebate pool are conserved, this means that we are
	// not able to extract more rewards than we initially deposited
	async function shouldConserveBalances(testCases: RebateTestCase[], alpha: RebateRatio) {
		const [alphaNumerator, alphaDenominator] = alpha
		await mockRebatePool.setRebateRatio(alphaNumerator, alphaDenominator)

		let totalFees = toBN(0)
		for (const testCase of testCases) {
			totalFees = totalFees.add(toBCT(testCase.fees))
			await mockRebatePool.add(bardsCurationToken.address, toBCT(testCase.fees), toBCT(testCase.stake))
		}

		let totalRewards = toBN(0)
		for (const testCase of testCases) {
			const rewards = await redeem(bardsCurationToken.address, toBCT(testCase.fees), toBCT(testCase.stake))
			totalRewards = totalRewards.add(rewards)
		}
		expect(toBCT(toFixed(totalRewards))).lte(toBCT(toFixed(totalFees)))
	}

	beforeEach(async function () {
		thisBardsStaking = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy(
			bardsHub.address,
			bancorFormula.address,
			bardsShareToken.address,
			DEFAULTS.staking.reserveRatio,
			DEFAULTS.staking.stakingTaxPercentage,
			DEFAULTS.staking.minimumStake,
			testWallet.address,
			DEFAULTS.staking.alphaNumerator,
			DEFAULTS.staking.alphaDenominator,
			DEFAULTS.staking.thawingPeriod
		);
		await bardsHub.connect(governance).registerContract(
			utils.id('thisBardsStaking'),
			thisBardsStaking.address
		);
		// Give some funds to the testWallet
		await bardsCurationToken.connect(governance).mint(userTwoAddress, testTokens)
		await approveToken(thisBardsStaking.address, MaxUint256);
		await bardsCurationToken.connect(userTwo).approve(thisBardsStaking.address, MaxUint256);
	})



	context('configuration', () => {
		context('defaultStakingReserveRatio', function () {
			it('should set `defaultStakingReserveRatio`', async function () {
				// Set right in the constructor
				expect(await thisBardsStaking.defaultStakingReserveRatio()).eq(DEFAULTS.staking.reserveRatio)

				// Can set if allowed
				const newValue = toBN('100')
				await thisBardsStaking.connect(governance).setDefaultReserveRatio(newValue)
				expect(await thisBardsStaking.defaultStakingReserveRatio()).eq(newValue)
			})

			it('reject set `defaultStakingReserveRatio` if out of bounds', async function () {
				await expect(
					thisBardsStaking.connect(governance).setDefaultReserveRatio(0)
				).to.be.revertedWith('Default reserve ratio must be > 0')

				await expect(
					thisBardsStaking.connect(governance).setDefaultReserveRatio(BPS_MAX + 1)
				).to.be.revertedWith('Default reserve ratio cannot be higher than MAX_PPM')
			})

			it('reject set `defaultStakingReserveRatio` if not allowed', async function () {
				await expect(
					thisBardsStaking.setDefaultReserveRatio(DEFAULTS.staking.reserveRatio)
				).to.be.revertedWith('Only governance can call')
			})
		});

		context('minimumStaking', function () {
			it('should set `minimumStaking`', async function () {
				// Set right in the constructor
				expect(await thisBardsStaking.minimumStaking()).eq(DEFAULTS.staking.minimumStake)

				// Can set if allowed
				const newValue = toBN('100')
				await thisBardsStaking.connect(governance).setMinimumStaking(newValue)
				expect(await thisBardsStaking.minimumStaking()).eq(newValue)
			})

			it('reject set `minimumStaking` if out of bounds', async function () {
				await expect(
					thisBardsStaking.connect(governance).setMinimumStaking(0)
				).to.be.revertedWith('Minimum curation deposit cannot be 0')
			})

			it('reject set `minimumStaking` if not allowed', async function () {
				await expect(
					thisBardsStaking.setMinimumStaking(DEFAULTS.staking.minimumStake)
				).to.be.revertedWith('Only governance can call')
			})
		})

		context('stakingTaxPercentage', function () {
			it('should set `stakingTaxPercentage`', async function () {
				const stakingTaxPercentage = DEFAULTS.staking.stakingTaxPercentage

				// Set new value
				await thisBardsStaking.connect(governance).setStakingTaxPercentage(0)
				await thisBardsStaking.connect(governance).setStakingTaxPercentage(stakingTaxPercentage)
			})

			it('reject set `stakingTaxPercentage` if out of bounds', async function () {
				await expect(
					thisBardsStaking.connect(governance).setStakingTaxPercentage(BPS_MAX + 1)
				).to.be.revertedWith('Staking tax percentage must be below or equal to MAX_BPS')
			})

			it('reject set `stakingTaxPercentage` if not allowed', async function () {
				await expect(
					thisBardsStaking.setStakingTaxPercentage(0)
				).to.be.revertedWith('Only governance can call')
			})
		})

		context('bardsShareTokenImpl', function () {
			it('should set `bardsShareTokenImpl`', async function () {
				const newBardsShareTokenImpl = bardsShareToken.address;
				await thisBardsStaking.connect(governance).setBardsShareTokenImpl(newBardsShareTokenImpl)
			})

			it('reject set `bardsShareTokenImpl` to empty value', async function () {
				const newBardsShareTokenImpl = AddressZero
				const tx = 
				await expect(
					thisBardsStaking.connect(governance).setBardsShareTokenImpl(newBardsShareTokenImpl)
				).to.be.revertedWith('Token Impl must be non-empty')
			})

			it('reject set `bardsShareTokenImpl` to non-contract', async function () {
				const newBardsShareTokenImpl = randomAddress()
				await expect(
					thisBardsStaking.connect(governance).setBardsShareTokenImpl(newBardsShareTokenImpl)
				).to.be.revertedWith('Token Impl must be a contract')
			})

			it('reject set `bardsShareTokenImpl` if not allowed', async function () {
				const newBardsShareTokenImpl = bardsShareToken.address
				await expect(
					thisBardsStaking.setBardsShareTokenImpl(newBardsShareTokenImpl)
				).to.be.revertedWith('Only governance can call')
			})
		})

		context('stakingAddress', function () {
			it('should set `stakingAddress`', async function () {
				// Set new value
				await thisBardsStaking.connect(governance).setStakingAddress(testWallet.address)
			})

			it('reject set `stakingAddress` if zero address', async function () {
				await expect(
					thisBardsStaking.connect(governance).setStakingAddress(ZERO_ADDRESS)
				).to.be.revertedWith('staking address must not be address(0)')
			})

			it('reject set `stakingAddress` if not allowed', async function () {
				await expect(
					thisBardsStaking.setStakingAddress(testWallet.address)
				).to.be.revertedWith('Only governance can call')
			})
		})

		context('channelDisputeEpochs', function () {
			it('should set `channelDisputeEpochs`', async function () {
				const newValue = toBN('5')
				await thisBardsStaking.connect(governance).setChannelDisputeEpochs(newValue)
				expect(await thisBardsStaking.channelDisputeEpochs()).eq(newValue)
			})

			it('reject set `channelDisputeEpochs` if not allowed', async function () {
				const newValue = toBN('5')
				await expect(
					thisBardsStaking.setChannelDisputeEpochs(newValue)
				).to.be.revertedWith('Only governance can call')
			})

			it('reject set `channelDisputeEpochs` to zero', async function () {
				await expect(
					thisBardsStaking.connect(governance).setChannelDisputeEpochs(0)
				).to.be.revertedWith('!channelDisputeEpochs')
			})
		})

		context('maxAllocationEpochs', function () {
			it('should set `maxAllocationEpochs`', async function () {
				const newValue = toBN('5')
				await thisBardsStaking.connect(governance).setMaxAllocationEpochs(newValue)
				expect(await thisBardsStaking.maxAllocationEpochs()).eq(newValue)
			})

			it('reject set `maxAllocationEpochs` if not allowed', async function () {
				const newValue = toBN('5')
				await expect(
					thisBardsStaking.setMaxAllocationEpochs(newValue)
				).revertedWith('Only governance can call')
			})
		})

		context('thawingPeriod', function () {
			it('should set `thawingPeriod`', async function () {
				const newValue = toBN('5')
				await thisBardsStaking.connect(governance).setThawingPeriod(newValue)
				expect(await thisBardsStaking.thawingPeriod()).eq(newValue)
			})

			it('reject set `thawingPeriod` if not allowed', async function () {
				const newValue = toBN('5')
				await expect(
					thisBardsStaking.setThawingPeriod(newValue)
				).to.be.revertedWith('Only governance can call')
			})

			it('reject set `thawingPeriod` to zero', async function () {
				const tx =
				await expect(
					thisBardsStaking.connect(governance).setThawingPeriod(0)
				).to.be.revertedWith('!thawingPeriod')
			})
		})

		context('rebateRatio', function () {
			it('should be setup on init', async function () {
				expect(await thisBardsStaking.alphaNumerator()).eq(toBN(85))
				expect(await thisBardsStaking.alphaDenominator()).eq(toBN(100))
			})

			it('should set `rebateRatio`', async function () {
				await thisBardsStaking.connect(governance).setRebateRatio(5, 6)
				expect(await thisBardsStaking.alphaNumerator()).eq(toBN(5))
				expect(await thisBardsStaking.alphaDenominator()).eq(toBN(6))
			})

			it('reject set `rebateRatio` if out of bounds', async function () {
				await expect(
					thisBardsStaking.connect(governance).setRebateRatio(0, 1)
				).to.be.revertedWith('!alpha')

				await expect(
					thisBardsStaking.connect(governance).setRebateRatio(1, 0)
				).to.be.revertedWith('!alpha')
			})

			it('reject set `rebateRatio` if not allowed', async function () {
				await expect(
					thisBardsStaking.setRebateRatio(1, 1)
				).to.be.revertedWith('Only governance can call')
			})
		})

	});

	context('Collecting', async function () {
		beforeEach(async function () {
			// console.log(thisBardsStaking.address);
			// await bardsHub.connect(governance).registerContract(
			// 	utils.id('BardsStaking'),
			// 	thisBardsStaking.address
			// );

			// await expect(
			// 	thisBardsStaking.syncAllContracts()
			// ).to.not.be.reverted;

			await expect(
				bardsHub.createProfile({
					to: userAddress,
					curationType: CurationType.Profile,
					profileId: 0,
					curationId: 0,
					tokenContractPointed: ZERO_ADDRESS,
					tokenIdPointed: 0,
					handle: randomInt(5).toString() + MOCK_PROFILE_HANDLE,
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

		it('reject collect tokens distributed to the zero allocation Id.', async function () {
			await expect(
				thisBardsStaking.connect(userTwo).collect(
					bardsCurationToken.address,
					toBCT('10'),
					0
				)
			).to.be.revertedWith('!alloc')
		})

		it('should collect tokens distributed to the staking pool', async function () {
			await shouldCollect(toBCT('1'))
			await shouldCollect(toBCT('10'))
			await shouldCollect(toBCT('100'))
			await shouldCollect(toBCT('200'))
			await shouldCollect(toBCT('500.25'))
		})

	})

	context('bonding curve', function () {
		it('reject convert share to tokens if curation not initted', async function () {
			await expect(
				thisBardsStaking.shareToTokens(FIRST_PROFILE_ID, toBCT('100'))
			).revertedWith('Curation must be built to perform calculations')
		})

		it('convert share to tokens', async function () {
			// Staking
			await thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToStake)

			// Conversion
			const shares = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
			const expectedTokens = await thisBardsStaking.shareToTokens(FIRST_PROFILE_ID, shares)
			expect(expectedTokens).eq(tokensToStake)
		})

		it('convert share to tokens (with staking tax)', async function () {
			// Set curation tax
			const stakingTaxPercentage = 50000 // 5%
			await thisBardsStaking.connect(governance).setStakingTaxPercentage(stakingTaxPercentage)

			// Staking
			const expectedStakingTax = tokensToStake.mul(stakingTaxPercentage).div(BPS_MAX)
			const { 1: stakingTax } = await thisBardsStaking.tokensToShare(
				FIRST_PROFILE_ID,
				tokensToStake,
			)
			await thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToStake)

			// Conversion
			const shares = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
			const tokens = await thisBardsStaking.shareToTokens(FIRST_PROFILE_ID, shares)
			expect(tokens).eq(tokensToStake.sub(expectedStakingTax))
			expect(expectedStakingTax).eq(stakingTax)
		})

		it('convert tokens to share', async function () {
			// Conversion
			const tokens = toBCT('1000')
			const { 0: share } = await thisBardsStaking.tokensToShare(FIRST_PROFILE_ID, tokens)
			expect(share).eq(toBN('9999999999999999999'))
		})

		it('convert tokens to signal if non-curated subgraph', async function () {
			const tokens = toBCT('1')
			await expect(
				thisBardsStaking.tokensToShare(FIRST_PROFILE_ID + 1, tokens)
			).to.be.revertedWith('Curation staking is below minimum required')
		})
	})

	context('Staking', () => {
		context('> when not staked', function () {
			context('isStaked', function () {
				it('should not have stakes', async function () {
					expect(await thisBardsStaking.isStaked(FIRST_PROFILE_ID)).eq(false)
				})
			})

			context('stake', function () {
				beforeEach(async function () {
					thisBardsStaking = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy(
						bardsHub.address,
						bancorFormula.address,
						bardsShareToken.address,
						DEFAULTS.staking.reserveRatio,
						DEFAULTS.staking.stakingTaxPercentage,
						DEFAULTS.staking.minimumStake,
						testWallet.address,
						DEFAULTS.staking.alphaNumerator,
						DEFAULTS.staking.alphaDenominator,
						DEFAULTS.staking.thawingPeriod
					);
					await bardsHub.connect(governance).registerContract(
						utils.id('thisBardsStaking'),
						thisBardsStaking.address
					);
					await approveToken(thisBardsStaking.address, MaxUint256);
					await bardsCurationToken.connect(userTwo).approve(thisBardsStaking.address, MaxUint256);
				});
				it('reject stake zero tokens', async function () {
					await expect(
						thisBardsStaking.stake(FIRST_PROFILE_ID, toBCT('0'))
					).to.be.revertedWith('Cannot deposit zero tokens')
				})

				it('reject stake less than minimum staking', async function () {
					await thisBardsStaking.connect(governance).setMinimumStaking(DEFAULTS.staking.minimumStake);
					expect(toBCT('1')).lte(await thisBardsStaking.minimumStaking())
					await expect(
						thisBardsStaking.stake(FIRST_PROFILE_ID, toBCT('1'))
					).revertedWith('!minimumStaking')
				})

				it('should stake tokens', async function () {
					await shouldStake(tokensToStake, shareof100token)
				})

				it('should stake tokens = minimumStaking', async function () {
					await shouldStake(await thisBardsStaking.minimumStaking(), toBCT('1'))
				})

				it('should get share according to bonding curve (and account for staking tax)', async function () {
					// Set curation tax
					await thisBardsStaking.connect(governance).setStakingTaxPercentage(50000) // 5%

					// Mint
					const tokensToDeposit = toBCT('1000')
					const { 0: expectedSignal } = await thisBardsStaking.tokensToShare(
						FIRST_PROFILE_ID,
						tokensToDeposit,
					)
					await shouldStake(tokensToDeposit, expectedSignal)
				})

			})

			context('unstake', function () {
				it('reject unstake tokens', async function () {
					const sharesToUnstake = toBCT('2')
					await expect(
						thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, sharesToUnstake)
					).to.be.revertedWith('Cannot burn more share than you own')
				})
			})
		})

		context('> when staked', function () {
			beforeEach(async function () {
				thisBardsStaking = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy(
					bardsHub.address,
					bancorFormula.address,
					bardsShareToken.address,
					DEFAULTS.staking.reserveRatio,
					DEFAULTS.staking.stakingTaxPercentage,
					DEFAULTS.staking.minimumStake,
					testWallet.address,
					DEFAULTS.staking.alphaNumerator,
					DEFAULTS.staking.alphaDenominator,
					DEFAULTS.staking.thawingPeriod
				);
				await bardsHub.connect(governance).registerContract(
					utils.id('thisBardsStaking'),
					thisBardsStaking.address
				);
				await approveToken(thisBardsStaking.address, MaxUint256);
				await bardsCurationToken.connect(userTwo).approve(thisBardsStaking.address, MaxUint256);
				await thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, toBCT('100'));
			});

			context('isStaked', function () {
				it('should have stakes', async function () {
					expect(await thisBardsStaking.isStaked(FIRST_PROFILE_ID)).eq(true)
				})
			})

			context('stake', function () {
				it('should allow re-staking', async function () {
					await shouldStake(tokensToStake, toBN('1309858294831200060'))
				})

				it('reject to stake under the minimum staking after unstake', async function () {
					// Unstake
					const shareStaked = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
					await thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, shareStaked)
					
					// Stake should require to go over the minimum stake
					await expect(
						thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, toBCT('1'))
					).revertedWith('!minimumStaking')
				})
			})

			context('unstake', function () {
				it('should unstake and lock tokens for thawing period', async function () {
					const shareStaked = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)

					// Unstake
					await expect(
						thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, shareStaked.div(2))
					).to.not.be.reverted;

				})

				it('reject unstake zero tokens', async function () {
					await expect(
						thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, toBCT('0'))
					).to.be.revertedWith('Cannot burn zero share')
				})

			})
		})
	})

	context('Unstaking', () => {
		beforeEach(async function () {
			thisBardsStaking = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy(
				bardsHub.address,
				bancorFormula.address,
				bardsShareToken.address,
				DEFAULTS.staking.reserveRatio,
				DEFAULTS.staking.stakingTaxPercentage,
				DEFAULTS.staking.minimumStake,
				testWallet.address,
				DEFAULTS.staking.alphaNumerator,
				DEFAULTS.staking.alphaDenominator,
				DEFAULTS.staking.thawingPeriod
			);
			await bardsHub.connect(governance).registerContract(
				utils.id('thisBardsStaking'),
				thisBardsStaking.address
			);
			await approveToken(thisBardsStaking.address, MaxUint256);
			await bardsCurationToken.connect(userTwo).approve(thisBardsStaking.address, MaxUint256);
			await thisBardsStaking.connect(userTwo).stake(FIRST_PROFILE_ID, tokensToStake);
		})

		it('reject redeem more than a delegator owns', async function () {
			await expect(
				thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, shareof100token.mul(2))
			).to.be.revertedWith('Cannot burn more share than you own')
		})

		it('reject redeem zero share', async function () {
			await expect(
				thisBardsStaking.connect(userTwo).unstake(FIRST_PROFILE_ID, toBCT('0'))
			).to.be.revertedWith('Cannot burn zero share')
		})

		it('should allow to redeem *partially*', async function () {
			// Redeem just one signal
			const shareToRedeem = toBCT('1')
			const expectedTokens = toBCT('53.245553203367586653')
			await shouldUnstake(shareToRedeem, expectedTokens)
		})

		it('should allow to redeem *fully*', async function () {
			// Get all signal of the curator
			const shareToRedeem = await thisBardsStaking.getDelegatorShare(userTwoAddress, FIRST_PROFILE_ID)
			const expectedTokens = tokensToStake
			await shouldUnstake(shareToRedeem, expectedTokens)
		})

		it('should allow to redeem back below minimum staking', async function () {
			// Redeem "almost" all share
			const shares = await thisBardsStaking.getDelegatorShare(userTwoAddress, FIRST_PROFILE_ID)
			const sharesToRedeem = shares.sub(toBCT('0.000001'))
			const expectedTokens = await thisBardsStaking.shareToTokens(FIRST_PROFILE_ID, sharesToRedeem)
			await shouldUnstake(sharesToRedeem, expectedTokens)

			// The pool should have less tokens that required by minimumStaking
			const afterPoolTokens = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
			expect(afterPoolTokens).lt(await thisBardsStaking.minimumStaking())
		})
	})

	context('Conservation', async function () {
		it('should match multiple stakings and redeems back to initial state', async function () {
			this.timeout(60000) // increase timeout for test runner

			const totalDeposits = toBCT('1000')

			// Staking multiple times
			let totalShare = toBCT('0')
			for (const tokensToDeposit of chunkify(totalDeposits, 10)) {
				const stakingOut = await stakingReturningPair(thisBardsStaking, userTwo, toBN(FIRST_PROFILE_ID), tokensToDeposit);
				totalShare = totalShare.add(stakingOut[0])
			}

			// Redeem share multiple times
			let totalTokens = toBCT('0')
			for (const shareToRedeem of chunkify(totalShare, 10)) {
				const tokenOut = await unstakingReturningPair(thisBardsStaking, userTwo, toBN(FIRST_PROFILE_ID), shareToRedeem)

				totalTokens = totalTokens.add(tokenOut)
			}

			// Conservation of work
			const afterPoolShare = await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID)
			const afterPoolToken = await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID)
			expect(afterPoolToken).eq(toBCT('0'))
			expect(afterPoolShare).eq(toBCT('0'))
			expect(await thisBardsStaking.isStaked(FIRST_PROFILE_ID)).eq(false)
			expect(totalDeposits).eq(totalTokens)
		})
	})

	context('Multiple staking', async function () {
		it('should staking less share every time due to the bonding curve', async function () {
			const tokensToDepositMany = [
				toBCT('1000'), // should mint if we start with number above minimum deposit
				toBCT('1000'), // every time it should mint less BST due to bonding curve...
				toBCT('1000'),
				toBCT('1000'),
				toBCT('2000'),
				toBCT('2000'),
				toBCT('123'),
				toBCT('1'), // should mint below minimum deposit
			]
			for (const tokensToDeposit of tokensToDepositMany) {
				const expectedShare = await calcBondingCurve(
					await thisBardsStaking.getStakingPoolShare(FIRST_PROFILE_ID),
					await thisBardsStaking.getStakingPoolToken(FIRST_PROFILE_ID),
					await thisBardsStaking.defaultStakingReserveRatio(),
					tokensToDeposit,
				)
				const stakingOut = await stakingReturningPair(thisBardsStaking, userTwo, toBN(FIRST_PROFILE_ID), tokensToDeposit);
				expect(toRound(expectedShare)).eq(toRound(toFloat(stakingOut[0])))
			}
		})

		it('should staking when using the edge case of linear function', async function () {
			this.timeout(60000) // increase timeout for test runner

			// Setup edge case like linear function: 1 GRT = 1 GCS
			await thisBardsStaking.connect(governance).setMinimumStaking(toBCT('1'))
			await thisBardsStaking.connect(governance).setDefaultReserveRatio(BPS_MAX)

			const tokensToDepositMany = [
				toBCT('1000'), // should mint if we start with number above minimum deposit
				toBCT('1000'), // every time it should mint less BST due to bonding curve...
				toBCT('1000'),
				toBCT('1000'),
				toBCT('2000'),
				toBCT('2000'),
				toBCT('123'),
				toBCT('1'), // should mint below minimum deposit
			]

			// Mint multiple times
			for (const tokensToDeposit of tokensToDepositMany) {
				const stakingOut = await stakingReturningPair(thisBardsStaking, userTwo, toBN(FIRST_PROFILE_ID), tokensToDeposit);
				expect(tokensToDeposit).eq(stakingOut[0]) // we compare 1:1 ratio
			}
		})
	})

	context('Rebate', async function () {
		beforeEach(async function () {
			mockRebatePool = await new MockRebatePool__factory(bardsStakingLibs, deployer).deploy();
		})

		context('should match cobb-douglas Solidity implementation', function () {
			context('normal test case', function () {
				testAlphas(shouldMatchFormulas, testCases)
			})

			context('edge #1 test case', function () {
				testAlphas(shouldMatchFormulas, edgeCases1)
			})
		})

		context('should match rewards out from rebates', function () {
			context('normal test case', function () {
				testAlphas(shouldMatchOut, testCases)
			})

			context('edge #1 test case', function () {
				testAlphas(shouldMatchOut, edgeCases1)
			})
		})

		context('should always be that sum of rebate rewards obtained <= to total rewards', function () {
			context('normal test case', function () {
				testAlphas(shouldConserveBalances, testCases)
			})

			context('edge #1 test case', function () {
				testAlphas(shouldConserveBalances, edgeCases1)
			})
		})
	})

})
