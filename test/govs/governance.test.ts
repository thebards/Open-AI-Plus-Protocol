import '@nomiclabs/hardhat-ethers';
import "@nomicfoundation/hardhat-chai-matchers";
import { expect } from 'chai';
import { ERRORS } from '../utils/Errors';
import { 
	governance, 
	bardsHub, 
	makeSuiteCleanRoom, 
	userAddress, 
	ProtocolState, 
	errorsLib 
} from '../__setup.test';

makeSuiteCleanRoom('Governance Functions', function () {
	context('Negative Stories', function () {
		it('User should not be able to call governance functions', async function () {
			await expect(
				bardsHub.setGovernance(userAddress)
			).to.be.revertedWithCustomError(errorsLib, ERRORS.NOT_GOVERNANCE);

			await expect(
				bardsHub.whitelistMarketModule(userAddress, true)
			).to.be.revertedWithCustomError(errorsLib, ERRORS.NOT_GOVERNANCE);
		});
	});

	context('Stories', function () {
		it('Governance should successfully whitelist and unwhitelist modules', async function () {
			await expect(
				bardsHub.connect(governance).whitelistMarketModule(userAddress, true)
			).to.not.be.reverted;
			expect(
				await bardsHub.isMarketModuleWhitelisted(userAddress)
			).to.eq(true);

			await expect(
				bardsHub.connect(governance).whitelistMarketModule(userAddress, false)
			).to.not.be.reverted;
			expect(
				await bardsHub.isMarketModuleWhitelisted(userAddress)
			).to.eq(false);
		});

		it('Governance should successfully change the governance address', async function () {
			await expect(
				bardsHub.connect(governance).setGovernance(userAddress)
			).to.not.be.reverted;
		});
	});
})