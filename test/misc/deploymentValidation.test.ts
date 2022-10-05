import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { 
	BardsCurationToken__factory, 
	BardsDaoData__factory, 
	BardsHub__factory, 
	BardsStaking__factory, 
	CloneMinter__factory, 
	EmptyMinter__factory, 
	EpochManager__factory, 
	FixPriceMarketModule__factory, 
	FreeMarketModule__factory, 
	RewardsManager__factory, 
	TransferMinter__factory, 
	TransparentUpgradeableProxy__factory 
} from '../../dist/types';
import {
	ZERO_ADDRESS,
	DEFAULTS,
	BPS_MAX,
	BARDS_HUB_NFT_NAME,
	BARDS_HUB_NFT_SYMBOL,
	PROTOCOL_FEE,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';

import {
	bardsHub,
	testWallet,
	bardsShareToken,
	bardsStakingLibs,
	deployer,
	bancorFormula,
	userAddress,
	errorsLib,
	makeSuiteCleanRoom,
	royaltyEngine,
	bardsHubImpl,
	governanceAddress,
	user,
	hubLibs,
	deployerAddress,
	daoTreasuryAddress
} from '../__setup.test';

makeSuiteCleanRoom('Deployment Validation', () => {

	it('Should fail to deploy a epoch manager moudle implementation with zero address hub', async function () {
		let epochManagerImpl = await new EpochManager__factory(deployer).deploy();
		let epochManagerData = epochManagerImpl.interface.encodeFunctionData(
			'initialize',
			[
				ZERO_ADDRESS,
				DEFAULTS.epochs.lengthInBlocks
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				epochManagerImpl.address,
				deployerAddress,
				epochManagerData
			)
		).to.be.revertedWith("HUB must be set");
	});

	it('Should fail to deploy a reward manager moudle implementation with zero address hub', async function () {
		let rewardsManagerImpl = await new RewardsManager__factory(deployer).deploy();
		let rewardsManagerData = rewardsManagerImpl.interface.encodeFunctionData(
			'initialize',
			[
				ZERO_ADDRESS,
				DEFAULTS.rewards.issuanceRate,
				DEFAULTS.rewards.inflationChange,
				DEFAULTS.rewards.targetBondingRate
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				rewardsManagerImpl.address,
				deployerAddress,
				rewardsManagerData
			)
		).to.be.revertedWith("HUB must be set");
	});

	it('Should fail to deploy a stake manager moudle implementation with zero address hub', async function () {
		let bardsStakingImpl = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy();
		let bardsStakingData = bardsStakingImpl.interface.encodeFunctionData(
			'initialize',
			[
				ZERO_ADDRESS,
				bancorFormula.address,
				bardsShareToken.address,
				DEFAULTS.staking.reserveRatio,
				DEFAULTS.staking.stakingTaxPercentage,
				DEFAULTS.staking.minimumStake,
				testWallet.address,
				DEFAULTS.staking.alphaNumerator,
				DEFAULTS.staking.alphaDenominator,
				DEFAULTS.staking.thawingPeriod,
				DEFAULTS.staking.channelDisputeEpochs,
				DEFAULTS.staking.maxAllocationEpochs
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsStakingImpl.address,
				deployerAddress,
				bardsStakingData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy a bards curation token contract implementation with zero address hub', async function () {
		let bardsCurationTokenImpl = await new BardsCurationToken__factory(deployer).deploy();
		let bardsCurationTokenData = bardsCurationTokenImpl.interface.encodeFunctionData(
			'initialize',
			[
				ZERO_ADDRESS,
				DEFAULTS.token.initialSupply
			]
		)

		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsCurationTokenImpl.address,
				deployerAddress,
				bardsCurationTokenData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy a market module implementation with zero address hub or zero address royaltyEngine', async function () {
		await expect(
			new FixPriceMarketModule__factory(deployer).deploy(
				ZERO_ADDRESS,
				royaltyEngine.address,
				testWallet.address
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);

		await expect(
			new FixPriceMarketModule__factory(deployer).deploy(
				bardsHub.address,
				ZERO_ADDRESS,
				testWallet.address
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);

		await expect(
			new FreeMarketModule__factory(deployer).deploy(
				ZERO_ADDRESS,
				royaltyEngine.address,
				testWallet.address
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);

		await expect(
			new FreeMarketModule__factory(deployer).deploy(
				bardsHub.address,
				ZERO_ADDRESS,
				testWallet.address
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
		
	});

	it('Should fail to deploy a minter moudle implementation with zero address hub', async function () {
		await expect(
			new TransferMinter__factory(deployer).deploy(
				ZERO_ADDRESS
			)
		).to.be.revertedWith("HUB must be set");

		await expect(
			new EmptyMinter__factory(deployer).deploy(
				ZERO_ADDRESS
			)
		).to.be.revertedWith("HUB must be set");

		await expect(
			new CloneMinter__factory(deployer).deploy(
				ZERO_ADDRESS
			)
		).to.be.revertedWith("HUB must be set");
	});

	it('Deployer should not be able to initialize implementation due to address(this) check', async function () {
		await expect(
			bardsHubImpl.initialize(
				BARDS_HUB_NFT_NAME, 
				BARDS_HUB_NFT_SYMBOL, 
				governanceAddress, 
				DEFAULTS.epochs.lengthInBlocks
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.CANNOT_INIT_IMPL
		);
	});

	it("User should fail to initialize BardsHub proxy after it's already been initialized via the proxy constructor", async function () {
		// Initialization happens in __setup.test.ts
		await expect(
			bardsHub.connect(user).initialize(
				'name', 
				'symbol', 
				userAddress, 
				DEFAULTS.epochs.lengthInBlocks)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INITIALIZED
		);
	});

	it('Deployer should deploy a BardsHub implementation, a proxy, initialize it, and fail to initialize it again', async function () {
		const newImpl = await new BardsHub__factory(hubLibs, deployer).deploy();

		let data = newImpl.interface.encodeFunctionData('initialize', [
			BARDS_HUB_NFT_NAME,
			BARDS_HUB_NFT_SYMBOL,
			governanceAddress,
			DEFAULTS.epochs.lengthInBlocks
		]);

		const proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
			newImpl.address,
			deployerAddress,
			data
		);

		await expect(
			BardsHub__factory.connect(proxy.address, user).initialize(
				'name', 
				'symbol', 
				userAddress,
				DEFAULTS.epochs.lengthInBlocks
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INITIALIZED
		);
	});

	it('User should not be able to call admin-only functions on proxy (should fallback) since deployer is admin', async function () {
		const proxy = TransparentUpgradeableProxy__factory.connect(bardsHub.address, user);
		await expect(proxy.upgradeTo(userAddress)).to.be.revertedWithoutReason;
		await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWithoutReason;
	});

	it('Deployer should be able to call admin-only functions on proxy', async function () {
		const proxy = TransparentUpgradeableProxy__factory.connect(bardsHub.address, deployer);
		const newImpl = await new BardsHub__factory(hubLibs, deployer).deploy();
		await expect(proxy.upgradeTo(newImpl.address)).to.not.be.reverted;
	});

	it('Deployer should transfer admin to user, deployer should fail to call admin-only functions, user should call admin-only functions', async function () {
		const proxy = TransparentUpgradeableProxy__factory.connect(bardsHub.address, deployer);

		await expect(proxy.changeAdmin(userAddress)).to.not.be.reverted;

		await expect(proxy.upgradeTo(userAddress)).to.be.revertedWithoutReason;
		await expect(proxy.upgradeToAndCall(userAddress, [])).to.be.revertedWithoutReason;

		const newImpl = await new BardsHub__factory(hubLibs, deployer).deploy();

		await expect(proxy.connect(user).upgradeTo(newImpl.address)).to.not.be.reverted;
	});


	it('Should fail to deploy Bards Dao Data contract with zero address governance', async function () {
		let bardsDaoDataImpl = await new BardsDaoData__factory(deployer).deploy()
		let bardsDaoDataData = bardsDaoDataImpl.interface.encodeFunctionData(
			'initialize',
			[
				ZERO_ADDRESS,
				daoTreasuryAddress,
				PROTOCOL_FEE,
				DEFAULT_CURATION_BPS,
				DEFAULT_STAKING_BPS
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsDaoDataImpl.address,
				deployerAddress,
				bardsDaoDataData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy Bards Dao Data contract with zero address treasury', async function () {
		let bardsDaoDataImpl = await new BardsDaoData__factory(deployer).deploy()
		let bardsDaoDataData = bardsDaoDataImpl.interface.encodeFunctionData(
			'initialize',
			[
				governanceAddress,
				ZERO_ADDRESS,
				PROTOCOL_FEE,
				DEFAULT_CURATION_BPS,
				DEFAULT_STAKING_BPS
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsDaoDataImpl.address,
				deployerAddress,
				bardsDaoDataData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy Bards Dao Data with protocol fee > MAX_BPS / 2', async function () {
		let bardsDaoDataImpl = await new BardsDaoData__factory(deployer).deploy()
		let bardsDaoDataData = bardsDaoDataImpl.interface.encodeFunctionData(
			'initialize',
			[
				governanceAddress,
				daoTreasuryAddress,
				BPS_MAX / 2 + 1,
				DEFAULT_CURATION_BPS,
				DEFAULT_STAKING_BPS
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsDaoDataImpl.address,
				deployerAddress,
				bardsDaoDataData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy Bards Dao Data with DefaultCurationBps > MAX_BPS / 2', async function () {
		let bardsDaoDataImpl = await new BardsDaoData__factory(deployer).deploy()
		let bardsDaoDataData = bardsDaoDataImpl.interface.encodeFunctionData(
			'initialize',
			[
				governanceAddress,
				daoTreasuryAddress,
				PROTOCOL_FEE,
				BPS_MAX / 2 + 1,
				DEFAULT_STAKING_BPS
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsDaoDataImpl.address,
				deployerAddress,
				bardsDaoDataData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Should fail to deploy Bards Dao Data with DefaultStakingBps > MAX_BPS / 2', async function () {
		let bardsDaoDataImpl = await new BardsDaoData__factory(deployer).deploy()
		let bardsDaoDataData = bardsDaoDataImpl.interface.encodeFunctionData(
			'initialize',
			[
				governanceAddress,
				daoTreasuryAddress,
				PROTOCOL_FEE,
				DEFAULT_CURATION_BPS,
				BPS_MAX / 2 + 1
			]
		)
		await expect(
			new TransparentUpgradeableProxy__factory(deployer).deploy(
				bardsDaoDataImpl.address,
				deployerAddress,
				bardsDaoDataData
			)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INIT_PARAMS_INVALID
		);
	});

	it('Validates BardsHub name & symbol', async function () {
		const name = await bardsHub.name();;
		const symbol = await bardsHub.symbol();

		expect(name).to.eq(BARDS_HUB_NFT_NAME);
		expect(symbol).to.eq(BARDS_HUB_NFT_SYMBOL);
	});
});