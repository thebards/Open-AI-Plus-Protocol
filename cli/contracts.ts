import { Contract, ContractFunction, ContractReceipt, ContractTransaction, providers, Signer } from 'ethers'
import { Provider } from '@ethersproject/providers'
import { AddressBook } from './addressBook'
import { logger } from './logging'
import { getContractAt } from './network'
import lodash from 'lodash'
import fs from 'fs'

import { 
	BardsHub,
	BardsDaoData,
	BancorFormula,
	BardsCurationToken,
	BardsShareToken,
	EpochManager,
	BardsStaking,
	RewardsManager,
	FixPriceMarketModule,
	FreeMarketModule,
	CloneMinter,
	TransferMinter,
	IWETH
} from '../dist/types/'

export interface NetworkContracts {
	BardsHub: BardsHub,
	BardsDaoData: BardsDaoData,
	BancorFormula: BancorFormula,
	BardsCurationToken: BardsCurationToken,
	BardsShareToken: BardsShareToken,
	EpochManager: EpochManager
	BardsStaking: BardsStaking
	RewardsManager: RewardsManager
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

// Returns a contract connect function that wrapps contract calls with wrapCalls
function getWrappedConnect(
	contract: Contract,
	contractName: string,
): (signerOrProvider: string | Provider | Signer) => Contract {
	const call = contract.connect.bind(contract)
	const override = (signerOrProvider: string | Provider | Signer): Contract => {
		const connectedContract = call(signerOrProvider)
		connectedContract.connect = getWrappedConnect(connectedContract, contractName)
		return wrapCalls(connectedContract, contractName)
	}
	return override
}

// Returns a contract with wrapped calls
// The wrapper will run the tx, wait for confirmation and log the details
function wrapCalls(contract: Contract, contractName: string): Contract {
	const wrappedContract = lodash.cloneDeep(contract)

	for (const fn of Object.keys(contract.functions)) {
		const call: ContractFunction<ContractTransaction> = contract.functions[fn]
		const override = async (...args: Array<any>): Promise<ContractTransaction> => {
			// Make the call
			const tx = await call(...args)
			logContractCall(tx, contractName, fn, args)

			// Wait for confirmation
			const receipt = await contract.provider.waitForTransaction(tx.hash)
			logContractReceipt(tx, receipt)
			return tx
		}

		wrappedContract.functions[fn] = override
		wrappedContract[fn] = override
	}

	return wrappedContract
}

function logContractCall(
	tx: ContractTransaction,
	contractName: string,
	fn: string,
	args: Array<any>,
) {
	const msg: string[] = []
	msg.push(`> Sent transaction ${contractName}.${fn}`)
	msg.push(`   sender: ${tx.from}`)
	msg.push(`   contract: ${tx.to}`)
	msg.push(`   params: [ ${args} ]`)
	msg.push(`   txHash: ${tx.hash}`)

	logToConsoleAndFile(msg)
}

function logContractReceipt(tx: ContractTransaction, receipt: ContractReceipt) {
	const msg: string[] = []
	msg.push(
		receipt.status ? `✔ Transaction succeeded: ${tx.hash}` : `✖ Transaction failed: ${tx.hash}`,
	)

	logToConsoleAndFile(msg)
}

function logToConsoleAndFile(msg: string[]) {
	const isoDate = new Date().toISOString()
	const fileName = `tx-${isoDate.substring(0, 10)}.log`

	msg.map((line) => {
		console.log(line)
		fs.appendFileSync(fileName, `[${isoDate}] ${line}\n`)
	})
}