import yargs, { Argv } from 'yargs'

import { logger } from '../../logging'
import { getContractAt, sendTransaction } from '../../network'
import { loadEnv, CLIArgs, CLIEnvironment } from '../../env'

import { ProtocolFunction } from './index'
import { BigNumber } from 'ethers'

export const settersList = {
}

const buildHelp = () => {
	let help = '$0 protocol set <fn> <params>\n\nGraph protocol configuration\n\nCommands:\n\n'
	for (const entry of Object.keys(settersList)) {
		help += '  $0 protocol set ' + entry + ' <params>\n'
	}
	return help
}

export const setProtocolParam = async (cli: CLIEnvironment, cliArgs: CLIArgs): Promise<void> => {
	logger.info(`Setting ${cliArgs.fn}...`)

	const fn: ProtocolFunction = settersList[cliArgs.fn]
	if (!fn) {
		logger.error(`Command ${cliArgs.fn} does not exist`)
		return
	}

	const addressEntry = cli.addressBook.getEntry(fn.contract)

	// Parse params
	const params = cliArgs.params.toString().split(',')
	const parsedParams: number[] = []
	for (const param of params) {
		try {
			const parsedParam = BigNumber.from(param)
			parsedParams.push(parsedParam.toNumber())
		} catch {
			parsedParams.push(param)
		}
	}
	logger.info(`params: ${parsedParams}`)

	// Send tx
	const contract = getContractAt(fn.contract, addressEntry.address).connect(cli.wallet)
	await sendTransaction(cli.wallet, contract, fn.name, parsedParams)
}

export const setCommand = {
	command: 'set <fn> <params>',
	describe: 'Set protocol parameter',
	builder: (yargs: Argv): yargs.Argv => {
		return yargs.usage(buildHelp())
	},
	handler: async (argv: CLIArgs): Promise<void> => {
		return setProtocolParam(await loadEnv(argv), argv)
	},
}