
import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { BardsHub__factory } from '../../dist/types';
import { waitForTx } from '../../cli/helpers/utils';

task('whitelist-currency', 'whitelists a currency in the bards hub')
	.addParam('gov')
	.addParam('proxyAddress')
	.addParam('currency')
	.addParam('whitelist')
	.setAction(async ({ gov, proxyAddress, currency, whitelist }, hre) => {
		const ethers = hre.ethers;
		const governance = await ethers.getSigner(gov);

		const bardsHub = BardsHub__factory.connect(proxyAddress, governance);;

		await waitForTx(bardsHub.connect(governance).whitelistCurrency(currency, whitelist));
	});