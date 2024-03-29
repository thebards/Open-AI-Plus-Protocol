import { constants, providers, utils } from 'ethers'
import yargs, { Argv } from 'yargs'

import { logger } from '../logging'
import { loadCallParams, readConfig, getContractConfig } from '../config'
import { cliOpts } from '../defaults'
import {
	isContractDeployed,
	deployContractAndSave,
	deployContractWithProxyAndSave,
	sendTransaction,
} from '../network'
import { loadEnv, CLIArgs, CLIEnvironment } from '../env'
import { confirm } from '../helpers'

const { EtherSymbol } = constants
const { formatEther } = utils

// Contracts are deployed in the order defined in this list
const allContracts = [
	"BardsHub",
	"BardsDaoData",
	"WETH",
	"EpochManager",
	"BardsCurationToken",
	"BardsShareToken",
	"RewardsManager",
	"BancorFormula",
	"BardsStaking",
	"RoyaltyEngine",
	"FixPriceMarketModule",
	"FreeMarketModule",
	"CloneMinter",
	"TransferMinter",
]

export const migrate = async (
	cli: CLIEnvironment,
	cliArgs: CLIArgs,
	autoMine = false,
): Promise<void> => {
	const bardsConfigPath = cliArgs.bardsConfig
	const force = cliArgs.force
	const contractName = cliArgs.contract
	const chainId = cli.chainId
	const skipConfirmation = cliArgs.skipConfirmation
	const proxyAdmin = cliArgs.proxyAdmin
	const callFn = cliArgs.callFn
	const contracts = cli.contracts

	// console.log(utils.id('WETH') + " WETH")
	// console.log(utils.id('BardsStaking') + " BardsStaking")
	// console.log(utils.id('BardsDaoData') + " BardsDaoData")
	// console.log(utils.id('BardsCurationToken') + " BardsCurationToken")
	// console.log(utils.id('RewardsManager') + " RewardsManager")
	// console.log(utils.id('EpochManager') + " EpochManager")
	// console.log(utils.id('TransferMinter') + " TransferMinter")

	// Ensure action
	const sure = await confirm('Are you sure you want to migrate contracts?', skipConfirmation)
	if (!sure) return

	if (chainId == 1337) {
		await (cli.wallet.provider as providers.JsonRpcProvider).send('evm_setAutomine', [true])
	}

	logger.info(`>>> Migrating contracts <<<\n`)

	const bardsConfig = readConfig(bardsConfigPath)

	////////////////////////////////////////
	// Deploy contracts

	// Filter contracts to be deployed
	if (contractName && !allContracts.includes(contractName)) {
		logger.error(`Contract ${contractName} not found in address book`)
		return
	}
	const deployContracts = contractName ? [contractName] : allContracts
	const pendingContractCalls: any[] = []

	// Deploy contracts
	logger.info(`>>> Contracts deployment\n`)
	for (const name of deployContracts) {
		// Get address book info
		const addressEntry = cli.addressBook.getEntry(name)
		const savedAddress = addressEntry && addressEntry.address

		logger.info(`= Deploy: ${name}`)

		// Check if contract already deployed
		const isDeployed = await isContractDeployed(
			name,
			savedAddress,
			cli.addressBook,
			cli.wallet.provider,
		)
		const contractConfig = getContractConfig(bardsConfig, cli.addressBook, name, cli)

		if (!force && isDeployed) {
			logger.info(`${name} is up to date, no action required`)
			logger.info(`Address: ${savedAddress}\n`)
			if (callFn && contractConfig.calls) {
				let contract = contracts[name]
				pendingContractCalls.push({ name, contract, calls: contractConfig.calls })
			}
			continue
		}
	
		// Get config and deploy contract
		const deployFn = contractConfig.proxy ? deployContractWithProxyAndSave : deployContractAndSave
		const contract = await deployFn(
			proxyAdmin,
			name, 
			contractConfig.params.map((a) => a.value), // keep only the values
			cli.wallet,
			cli.addressBook,
		)
		
		// Defer contract calls after deploying every contract
		if (contractConfig.calls) {
			pendingContractCalls.push({ name, contract, calls: contractConfig.calls })
		}
		console.log('\n')
	}
	logger.info('Contract deployments done! Contract calls are next')

	////////////////////////////////////////
	// Run contracts calls

	logger.info('')
	logger.info(`>>> Contracts calls\n`)
	if (pendingContractCalls.length > 0) {
		for (const entry of pendingContractCalls) {
			if (entry.calls.length == 0) continue

			logger.info(`= Config: ${entry.name}`)
			for (const call of entry.calls) {
				logger.info(`\n* Calling ${call.fn}:`)
				await sendTransaction(
					cli.wallet,
					entry.contract,
					call.fn,
					loadCallParams(call.params, cli.addressBook, cli),
				)
			}
			logger.info('')
		}
	} else {
		logger.info('Nothing to do')
	}

	////////////////////////////////////////
	// Print summary
	logger.info('')
	logger.info(`>>> Summary\n`)
	logger.info('All done!')
	const spent = formatEther(cli.balance.sub(await cli.wallet.getBalance()))
	const nTx = (await cli.wallet.getTransactionCount()) - cli.nonce
	logger.info(`Sent ${nTx} transaction${nTx === 1 ? '' : 's'} & spent ${EtherSymbol} ${spent}`)

	if (chainId == 1337) {
		await (cli.wallet.provider as providers.JsonRpcProvider).send('evm_setAutomine', [autoMine])
	}
}

export const migrateCommand = {
	command: 'migrate',
	describe: 'Migrate contracts',
	builder: (yargs: Argv): yargs.Argv => {
		return yargs.option('c', cliOpts.bardsConfig).option('n', {
			alias: 'contract',
			description: 'Contract name to deploy (all if not set)',
			type: 'string',
		})
	},
	handler: async (argv: CLIArgs): Promise<void> => {
		return migrate(await loadEnv(argv), argv)
	},
}