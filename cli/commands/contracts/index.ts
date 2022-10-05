import yargs, { Argv } from 'yargs'

import { anyCommand } from './any'

export const contractsCommand = {
	command: 'contracts',
	describe: 'Contract calls for all contracts',
	builder: (yargs: Argv): yargs.Argv => {
		return yargs
			.command(anyCommand)
	},
	handler: (): void => {
		yargs.showHelp()
	},
}