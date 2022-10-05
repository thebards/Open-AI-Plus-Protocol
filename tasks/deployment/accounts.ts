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
			governor,
			treasury,
			stakingTreasury,
			proxyAdmin
		] = await hre.ethers.getSigners()

		console.log(`- Deployer: ${deployer.address}`)
		console.log(`- Governor: ${governor.address}`)
		console.log(`- Dao Treasury: ${treasury.address}`)
		console.log(`- Staking Treasury: ${stakingTreasury.address}`)
		console.log(`- proxyAdmin: ${proxyAdmin.address}`)

		updateItemValue(bardsConfig, 'general/governor', governor.address)
		updateItemValue(bardsConfig, 'general/treasury', treasury.address)
		updateItemValue(bardsConfig, 'general/stakingTreasury', stakingTreasury.address)
		updateItemValue(bardsConfig, 'general/proxyAdmin', proxyAdmin.address)

		writeConfig(taskArgs.bardsConfig, bardsConfig.toString())
	})