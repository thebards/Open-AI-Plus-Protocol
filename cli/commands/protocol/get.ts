import yargs, { Argv } from 'yargs'

import { logger } from '../../logging'
import { getContractAt } from '../../network'
import { loadEnv, CLIArgs, CLIEnvironment } from '../../env'
import { ContractFunction } from 'ethers'

import { ProtocolFunction } from './index'

export const gettersList = {

}

const buildHelp = () => {
	let help = '$0 protocol get <fn> [params]\n\nBards protocol configuration\n\nCommands:\n\n'
	for (const entry of Object.keys(gettersList)) {
		help += '  $0 protocol get ' + entry + ' [params]\n'
	}
	return help
}

export const getProtocolParam = async (cli: CLIEnvironment, cliArgs: CLIArgs): Promise<void> => {
	logger.info(`Getting ${cliArgs.fn}...`)

	const fn: ProtocolFunction = gettersList[cliArgs.fn]
	if (!fn) {
		logger.error(`Command ${cliArgs.fn} does not exist`)
		return
	}

	const addressEntry = cli.addressBook.getEntry(fn.contract)

	// Parse params
	const params = cliArgs.params ? cliArgs.params.toString().split(',') : []

	// Send tx
	const contract = getContractAt(fn.contract, addressEntry.address).connect(cli.wallet)
	const contractFn: ContractFunction = contract.functions[fn.name]

	const [value] = await contractFn(...params)
	logger.info(`${fn.name} = ${value}`)
}

export const getCommand = {
	command: 'get <fn> [params]',
	describe: 'Get network parameter',
	builder: (yargs: Argv): yargs.Argv => {
		return yargs.usage(buildHelp())
	},
	handler: async (argv: CLIArgs): Promise<void> => {
		return getProtocolParam(await loadEnv(argv), argv)
	},
}