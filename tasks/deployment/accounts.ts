import { task } from 'hardhat/config'

import { cliOpts } from '../../cli/defaults'
import { updateItemValue, writeConfig } from '../../cli/config'

task('migrate:accounts', 'Creates protocol accounts and saves them in bards config')
	.addOptionalParam('bardsConfig', cliOpts.bardsConfig.description)
	.setAction(async (taskArgs, hre) => {
		const { bardsConfig, getDeployer } = hre.bards(taskArgs)

		console.log('> Generating addresses')

		const deployer = await getDeployer()
		const [
			,
			arbitrator,
			governor,
			authority,
			availabilityOracle,
			pauseGuardian,
			allocationExchangeOwner,
		] = await hre.ethers.getSigners()

		console.log(`- Deployer: ${deployer.address}`)
		console.log(`- Arbitrator: ${arbitrator.address}`)
		console.log(`- Governor: ${governor.address}`)
		console.log(`- Authority: ${authority.address}`)
		console.log(`- Availability Oracle: ${availabilityOracle.address}`)
		console.log(`- Pause Guardian: ${pauseGuardian.address}`)
		console.log(`- Allocation Exchange Owner: ${allocationExchangeOwner.address}`)

		updateItemValue(bardsConfig, 'general/arbitrator', arbitrator.address)
		updateItemValue(bardsConfig, 'general/governor', governor.address)
		updateItemValue(bardsConfig, 'general/authority', authority.address)
		updateItemValue(bardsConfig, 'general/availabilityOracle', availabilityOracle.address)
		updateItemValue(bardsConfig, 'general/pauseGuardian', pauseGuardian.address)
		updateItemValue(bardsConfig, 'general/allocationExchangeOwner', allocationExchangeOwner.address)

		writeConfig(taskArgs.bardsConfig, bardsConfig.toString())
	})