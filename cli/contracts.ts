import { providers, Signer } from 'ethers'

import { AddressBook } from './addressBook'
import { logger } from './logging'
import { getContractAt } from './network'

import { 
	BardsHub,
	BardsDaoData,
	BardsCurationToken,
	BardsShareToken,
	EpochManager,
	BardsStaking,
	RewardsManager,
	BancorFormula,
	FixPriceMarketModule,
	FreeMarketModule,
	CloneMinter,
	TransferMinter,
	IWETH
} from '../dist/types/'

export interface NetworkContracts {
	BardsHub: BardsHub,
	BardsDaoData: BardsDaoData,
	BardsCurationToken: BardsCurationToken,
	BardsShareToken: BardsShareToken,
	EpochManager: EpochManager
	BardsStaking: BardsStaking
	RewardsManager: RewardsManager
	BancorFormula: BancorFormula,
	FixPriceMarketModule: FixPriceMarketModule,
	FreeMarketModule: FreeMarketModule,
	CloneMinter: CloneMinter,
	TransferMinter: TransferMinter,
	IWETH: IWETH
}

export const loadContracts = (
	addressBook: AddressBook,
	signerOrProvider?: Signer | providers.Provider,
): NetworkContracts => {
	const contracts = {}
	for (const contractName of addressBook.listEntries()) {
		const contractEntry = addressBook.getEntry(contractName)
		try {
			const contract = getContractAt(contractName, contractEntry.address)
			contracts[contractName] = contract
			if (signerOrProvider) {
				contracts[contractName] = contracts[contractName].connect(signerOrProvider)
			}
		} catch (err) {
			logger.warn(`Could not load contract ${contractName} - ${err.message}`)
		}
	}
	return contracts as NetworkContracts
}