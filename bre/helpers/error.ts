import { HardhatPluginError } from 'hardhat/plugins'
import { logError } from '../logger'

export class BREPluginError extends HardhatPluginError {
	constructor(message: string) {
		super('BardsRuntimeEnvironment', message)
		logError(message)
	}
}