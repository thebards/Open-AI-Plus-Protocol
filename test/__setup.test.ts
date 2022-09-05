import { AbiCoder } from '@ethersproject/abi';
import '@nomiclabs/hardhat-ethers';
import "@nomicfoundation/hardhat-chai-matchers";
import { expect, use } from 'chai';
import { BytesLike, Signer, Wallet, utils } from 'ethers';
import { ethers } from 'hardhat';

import { ERRORS } from './utils/Errors';
import { 
	FAKE_PRIVATEKEY,
	PROTOCOL_FEE,
	BARDS_HUB_NFT_NAME,
	BARDS_HUB_NFT_SYMBOL,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS,
	DEFAULTS,
	ZERO_ADDRESS
 } from './utils/Constants';

import {
	revertToSnapshot,
	takeSnapshot
} from './utils/Helpers';

import {
	BardsHub,
	BardsHub__factory,
	Events,
	Events__factory,
	BardsDaoData,
	BardsDaoData__factory,
	FixPriceMarketModule,
	FixPriceMarketModule__factory,
	CurationHelpers,
	CurationHelpers__factory,
	TransparentUpgradeableProxy__factory,
	Errors,
	Errors__factory,
	RoyaltyEngine,
	RoyaltyEngine__factory,
	Minter,
	Minter__factory,
	WETH,
	WETH__factory,
	EpochManager,
	EpochManager__factory,
	RewardsManager,
	RewardsManager__factory,
	BardsCurationToken,
	BardsCurationToken__factory,
	BardsShareToken,
	BardsShareToken__factory,
	BardsStaking,
	BardsStaking__factory,
	BancorFormula,
	BancorFormula__factory,
	LibCobbDouglas,
	LibCobbDouglas__factory
} from '../typechain-types';

import { BardsHubLibraryAddresses} from "../typechain-types/factories/contracts/core/BardsHub__factory";
import { BardsStakingLibraryAddresses } from "../typechain-types/factories/contracts/core/tokens/BardsStaking__factory";

export enum ProtocolState {
	Unpaused,
	CurationPaused,
	Paused,
}

export enum CurationType{
	Profile,
	Content,
	Combined,
	Protfolio,
	Feed,
	Dapp
}

export const TREASURY_FEE_BPS = 50;
export const REFERRAL_FEE_BPS = 250;

export let accounts: Signer[];
export let deployer: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let governance: Signer;
export let royaltyEnginer: Signer;
export let deployerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let governanceAddress: string;
export let treasuryAddress: string;
export let royaltyEngineAddress: string;
export let testWallet: Wallet;
export let bardsHub: BardsHub;
export let bardsHubImpl: BardsHub;
export let bardsDaoData: BardsDaoData;
export let royaltyEngine: RoyaltyEngine;
export let minter: Minter;
export let epochManager: EpochManager;
export let rewardsManager: RewardsManager;
export let bardsCurationToken: BardsCurationToken;
export let bardsShareToken: BardsShareToken;
export let bardsStaking: BardsStaking;
export let bancorFormula: BancorFormula;
export let weth: WETH;
export let hubLibs: BardsHubLibraryAddresses;
export let bardsStakingLibs: BardsStakingLibraryAddresses;
export let fixPriceMarketModule: FixPriceMarketModule;
export let abiCoder: AbiCoder;
export let eventsLib: Events;
export let errorsLib: Errors;
export let mockMarketModuleInitData: BytesLike;
export let mockMintModuleInitData: BytesLike;
export let mockCurationMetaData: BytesLike;

export function makeSuiteCleanRoom(name: string, tests: () => void) {
	describe(name, () => {
		beforeEach(async function () {
			await takeSnapshot();
		});
		tests();
		afterEach(async function () {
			await revertToSnapshot();
		});
	});
}

before(async function () {
	abiCoder = ethers.utils.defaultAbiCoder;
	testWallet = new ethers.Wallet(FAKE_PRIVATEKEY).connect(ethers.provider);
	accounts = await ethers.getSigners();
	deployer = accounts[0];
	user = accounts[1];
	userTwo = accounts[2];
	userThree = accounts[4];
	governance = accounts[3];
	royaltyEnginer = accounts[4];

	deployerAddress = await deployer.getAddress();
	userAddress = await user.getAddress();
	userTwoAddress = await userTwo.getAddress();
	userThreeAddress = await userThree.getAddress();
	governanceAddress = await governance.getAddress();
	royaltyEngineAddress = await royaltyEnginer.getAddress();
	treasuryAddress = await accounts[4].getAddress();
	mockMarketModuleInitData = abiCoder.encode(
		['address', 'uint256', 'address', 'address', 'address'],
		[ZERO_ADDRESS, 0, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS]
	);
	mockMintModuleInitData = abiCoder.encode(
		['address', 'uint256', 'address', 'address', 'address'],
		[ZERO_ADDRESS, 0, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS]
	);
	mockCurationMetaData = abiCoder.encode(
		['address[]', 'address[]', 'uint32[]', 'uint32', 'uint32'],
		[[ZERO_ADDRESS], [ZERO_ADDRESS], [1000000], DEFAULT_CURATION_BPS, DEFAULT_CURATION_BPS]
	);

	bardsDaoData = await new BardsDaoData__factory(deployer).deploy(
		governanceAddress, 
		treasuryAddress, 
		PROTOCOL_FEE,
		DEFAULT_CURATION_BPS,
		DEFAULT_STAKING_BPS
	);

	// libs
	const curationHelpers = await new CurationHelpers__factory(deployer).deploy();
	hubLibs = {
		'contracts/utils/CurationHelpers.sol:CurationHelpers': curationHelpers.address
	};

	const cobbs = await new LibCobbDouglas__factory(deployer).deploy();
	bardsStakingLibs = {
		'contracts/utils/Cobbs.sol:LibCobbDouglas': cobbs.address
	}

	bardsHubImpl = await new BardsHub__factory(hubLibs, deployer).deploy();
	
	bardsHubImpl.initialize(
		BARDS_HUB_NFT_NAME,
		BARDS_HUB_NFT_SYMBOL,
		governanceAddress
	);
	let data = bardsHubImpl.interface.encodeFunctionData('initialize', [
		BARDS_HUB_NFT_NAME,
		BARDS_HUB_NFT_SYMBOL,
		governanceAddress,
	]);
	let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
		bardsHubImpl.address,
		deployerAddress,
		data
	);
	
	// Connect the hub proxy to the LensHub factory and the user for ease of use.
	bardsHub = BardsHub__factory.connect(proxy.address, user);

	// Bards Curation Tokens
	bardsCurationToken = await new BardsCurationToken__factory(deployer).deploy(
		bardsHub.address,
		DEFAULTS.token.initialSupply
	);
	// Bards Share Tokens
	bardsShareToken = await new BardsShareToken__factory(deployer).deploy();
	// Epoch Manager
	epochManager = await new EpochManager__factory(deployer).deploy(
		bardsHub.address,
		DEFAULTS.epochs.lengthInBlocks
	);
	// Reward Manager
	rewardsManager = await new RewardsManager__factory(deployer).deploy(bardsHub.address);
	// BancorFormula
	bancorFormula = await new BancorFormula__factory(deployer).deploy();
	// Bards Staking
	bardsStaking = await new BardsStaking__factory(bardsStakingLibs, deployer).deploy(
		bardsHub.address,
		bancorFormula.address,
		bardsShareToken.address,
		DEFAULTS.staking.reserveRatio,
		DEFAULTS.staking.stakingTaxPercentage,
		DEFAULTS.staking.minimumStake,
		testWallet.address
	);
	
	// WETH
	weth = await new WETH__factory(deployer).deploy();
	
	// Register contracts
	await bardsHub.connect(governance).registerContract(
		utils.id('BardsStaking'),
		bardsStaking.address
	);
	await bardsHub.connect(governance).registerContract(
		utils.id('IWETH'),
		weth.address
	);
	await bardsHub.connect(governance).registerContract(
		utils.id('BardsDaoData'),
		bardsDaoData.address
	);
	await bardsHub.connect(governance).registerContract(
		utils.id('BardsCurationToken'),
		bardsCurationToken.address
	);
	await bardsHub.connect(governance).registerContract(
		utils.id('RewardsManager'),
		rewardsManager.address
	);
	await bardsHub.connect(governance).registerContract(
		utils.id('EpochManager'),
		epochManager.address
	);

	// For Market Module
	royaltyEngine = await new RoyaltyEngine__factory(deployer).deploy(royaltyEngineAddress);
	minter = await new Minter__factory(deployer).deploy();


	// market and mint module
	fixPriceMarketModule = await new FixPriceMarketModule__factory(deployer).deploy(
		bardsHub.address,
		royaltyEngine.address
	);

	await expect(
		bardsHub.connect(governance).setState(ProtocolState.Unpaused)
	).to.not.be.reverted;
	await expect(
		bardsHub.connect(governance).whitelistProfileCreator(userAddress, true)
	).to.not.be.reverted;
	await expect(
		bardsHub.connect(governance).whitelistProfileCreator(userTwoAddress, true)
	).to.not.be.reverted;
	await expect(
		bardsHub.connect(governance).whitelistProfileCreator(userThreeAddress, true)
	).to.not.be.reverted;
	await expect(
		bardsHub.connect(governance).whitelistProfileCreator(testWallet.address, true)
	).to.not.be.reverted;

	expect(bardsHub).to.not.be.undefined;
	expect(bardsCurationToken).to.not.be.undefined;
	expect(bardsShareToken).to.not.be.undefined;
	expect(epochManager).to.not.be.undefined;
	expect(rewardsManager).to.not.be.undefined;
	expect(bancorFormula).to.not.be.undefined;
	expect(bardsStaking).to.not.be.undefined;

	// Event library deployment is only needed for testing and is not reproduced in the live environment
	eventsLib = await new Events__factory(deployer).deploy();
	errorsLib = await new Errors__factory(deployer).deploy();
});



