import { AbiCoder } from '@ethersproject/abi';
import '@nomiclabs/hardhat-ethers';
import "@nomicfoundation/hardhat-chai-matchers";
import { expect, use } from 'chai';
import { BytesLike, Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';

import { ERRORS } from './utils/Errors';
import { 
	FAKE_PRIVATEKEY,
	PROTOCOL_FEE,
	BARDS_HUB_NFT_NAME,
	BARDS_HUB_NFT_SYMBOL
 } from './utils/Constants';

import {
	revertToSnapshot,
	takeSnapshot,
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
	MarketModuleBase
} from '../typechain-types';

import { BardsHubLibraryAddresses } from "../typechain-types/factories/contracts/core/BardsHub__factory";

export enum ProtocolState {
	Unpaused,
	CurationPaused,
	Paused,
}

export let accounts: Signer[];
export let deployer: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let governance: Signer;
export let deployerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let governanceAddress: string;
export let treasuryAddress: string;
export let testWallet: Wallet;
export let bardsHub: BardsHub;
export let bardsHubImpl: BardsHub;
export let bardsDaoData: BardsDaoData;
export let hubLibs: BardsHubLibraryAddresses;
export let fixPriceMarketModule: FixPriceMarketModule;
export let abiCoder: AbiCoder;
export let eventsLib: Events;
export let errorsLib: Errors;
export let mockMarketModuleData: BytesLike;

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

	deployerAddress = await deployer.getAddress();
	userAddress = await user.getAddress();
	userTwoAddress = await userTwo.getAddress();
	userThreeAddress = await userThree.getAddress();
	governanceAddress = await governance.getAddress();
	treasuryAddress = await accounts[4].getAddress();
	mockMarketModuleData = abiCoder.encode(['uint256'], [1]);

	bardsDaoData = await new BardsDaoData__factory(deployer).deploy(
		governanceAddress, 
		treasuryAddress, 
		PROTOCOL_FEE
	);

	const curationHelpers = await new CurationHelpers__factory(deployer).deploy();
	hubLibs = {
		'contracts/utils/CurationHelpers.sol:CurationHelpers': curationHelpers.address
	};

	bardsHubImpl = await new BardsHub__factory(hubLibs, deployer).deploy(
		bardsDaoData.address
	);
	
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

	// market and mint module
	fixPriceMarketModule = await new FixPriceMarketModule__factory(deployer).deploy(bardsDaoData.address);

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

	// Event library deployment is only needed for testing and is not reproduced in the live environment
	eventsLib = await new Events__factory(deployer).deploy();
	errorsLib = await new Errors__factory(deployer).deploy();
});



