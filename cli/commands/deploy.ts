import yargs, { Argv } from 'yargs'

import {
	getContractAt,
	deployContract,
	deployContractAndSave,
	deployContractWithProxy,
	deployContractWithProxyAndSave,
} from '../network'
import { loadEnv, CLIArgs, CLIEnvironment } from '../env'
import { logger } from '../logging'
import { confirm } from '../helpers'

export const deploy = async (cli: CLIEnvironment, cliArgs: CLIArgs): Promise<void> => {
	const contractName = cliArgs.contract
	const initArgs = cliArgs.init
	const deployType = cliArgs.type
	const buildAcceptProxyTx = cliArgs.buildTx
	const skipConfirmation = cliArgs.skipConfirmation
	let proxyAdmin = cliArgs.proxyAdmin

	// Ensure action
	const sure = await confirm(`Are you sure to deploy ${contractName}?`, skipConfirmation)
	if (!sure) return

	// Deploy contract
	const contractArgs = initArgs ? initArgs.split(',') : []
	switch (deployType) {
		case 'deploy':
			logger.info(`Deploying contract ${contractName}...`)
			await deployContract(contractName, contractArgs, cli.wallet)
			break
		case 'deploy-save':
			logger.info(`Deploying contract ${contractName} and saving to address book...`)
			await deployContractAndSave(proxyAdmin, contractName, contractArgs, cli.wallet, cli.addressBook)
			break
		case 'deploy-with-proxy':
			proxyAdmin = cli.wallet

			logger.info(`Deploying contract ${contractName} with proxy ...`)
			await deployContractWithProxy(
				proxyAdmin,
				contractName,
				contractArgs,
				cli.wallet,
				buildAcceptProxyTx,
			)
			break
		case 'deploy-with-proxy-save':
			logger.info(`Deploying contract ${contractName} with proxy and saving to address book...`)
			await deployContractWithProxyAndSave(
				proxyAdmin,
				contractName,
				contractArgs,
				cli.wallet,
				cli.addressBook,
			)
			break
		default:
			logger.error('Please provide the correct option for deploy type')
	}
}

export const deployCommand = {
	command: 'deploy',
	describe: 'Deploy contract',
	builder: (yargs: Argv): yargs.Argv => {
		return yargs
			.option('x', {
				alias: 'init',
				description: 'Init arguments as comma-separated values',
				type: 'string',
				requiresArg: true,
			})
			.option('c', {
				alias: 'contract',
				description: 'Contract name to deploy',
				type: 'string',
				requiresArg: true,
				demandOption: true,
			})
			.option('t', {
				alias: 'type',
				description: 'Choose deploy, deploy-save, deploy-with-proxy, deploy-with-proxy-save',
				type: 'string',
				requiresArg: true,
				demandOption: true,
			})
			.option('b', {
				alias: 'build-tx',
				description: 'Build the acceptProxy tx and print it. Then use tx data with a multisig',
				default: false,
				type: 'boolean',
			})
	},
	handler: async (argv: CLIArgs): Promise<void> => {
		return deploy(await loadEnv(argv), argv)
	},
}