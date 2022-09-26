import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { ERRORS } from '../utils/Errors';

import {
	abiCoder,
	bardsHub,
	makeSuiteCleanRoom,
	user,
	deployer,
	governanceAddress,
	errorsLib,
	hubLibs,
} from '../__setup.test';

import {
	MockBardsHubWithBadRevision__factory,
	MockBardsHub__factory,
	TransparentUpgradeableProxy__factory
} from '../../typechain-types';
import { BARDS_HUB_NFT_NAME, BARDS_HUB_NFT_SYMBOL } from '../utils/Constants';

makeSuiteCleanRoom('Upgradeability', function () {
	const valueToSet = 123;

	it('Should fail to initialize an implementation with the same revision', async function () {
		const newImpl = await new MockBardsHubWithBadRevision__factory(deployer).deploy();
		const proxyHub = TransparentUpgradeableProxy__factory.connect(bardsHub.address, deployer);
		const hub = MockBardsHubWithBadRevision__factory.connect(proxyHub.address, user);

		await expect(
			proxyHub.upgradeTo(newImpl.address)
		).to.not.be.reverted;

		await expect(
			hub.initialize(valueToSet)
		).to.be.revertedWithCustomError(
			errorsLib,
			ERRORS.INITIALIZED
		);
	});

	// The LensHub contract's last storage variable by default is at the 32nd slot (index 31) and contains the emergency admin
	// We're going to validate the first 32 slots and the 33rd slot before and after the change
	it("Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate", async function () {
		// old hub
		const proxyHub = TransparentUpgradeableProxy__factory.connect(bardsHub.address, deployer);
		let prevStorage: string[] = [];
		for (let i = 0; i < 33; i++) {
			const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
			prevStorage.push(valueAt);
		}

		let prevNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 33);
		const formattedZero = abiCoder.encode(['uint256'], [0]);
		expect(prevNextSlot).to.eq(formattedZero);
		
		// new hub
		const newImpl = await new MockBardsHub__factory(deployer).deploy();
		await proxyHub.upgradeTo(newImpl.address);
		await expect(
			MockBardsHub__factory.connect(proxyHub.address, user).setAdditionalValue(valueToSet)
		).to.not.be.reverted;

		for (let i = 0; i < 33; i++) {
			const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
			expect(valueAt).to.eq(prevStorage[i]);
		}

		const newNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 33);
		const formattedValue = abiCoder.encode(['uint256'], [valueToSet]);
		expect(newNextSlot).to.eq(formattedValue);
	});
});