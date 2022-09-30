

import { task } from 'hardhat/config'
import { cliOpts } from '../../cli/defaults'
import { ProtocolState } from '../../cli/metadata'

task('migrate:unpause', 'Unpause protocol')
	.addOptionalParam('addressBook', cliOpts.addressBook.description)
	.addOptionalParam('bardsConfig', cliOpts.bardsConfig.description)
	.setAction(async (taskArgs, hre) => {
		const { contracts, getNamedAccounts } = hre.bards(taskArgs)
		const { governor } = await getNamedAccounts()

		console.log('> Unpausing protocol')
		const tx = await contracts.BardsHub.connect(governor).setState(ProtocolState.Unpaused)
		await tx.wait()
		console.log('Done!')
	})