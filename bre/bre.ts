import { HardhatConfig, HardhatRuntimeEnvironment, HardhatUserConfig } from 'hardhat/types'
import { extendConfig, extendEnvironment } from 'hardhat/config'
import { lazyFunction, lazyObject } from 'hardhat/plugins'

import { getAddressBook } from '../cli/addressBook'
import { loadContracts } from '../cli/contracts'
import { readConfig } from '../cli/config'
import {
	BardsNetworkEnvironment,
	BardsRuntimeEnvironment,
	BardsRuntimeEnvironmentOptions,
} from './typeExtensions'
import { getChains, getProviders, getAddressBookPath, getBardsConfigPaths } from './config'
import { getDeployer, getNamedAccounts, getTestAccounts, getWallet, getWallets } from './accounts'
import { logDebug, logWarn } from './logger'
import path from 'path'
import { EthersProviderWrapper } from '@nomiclabs/hardhat-ethers/internal/ethers-provider-wrapper'
import { Wallet } from 'ethers'

// Bards Runtime Environment (bre) extensions for the HRE

extendConfig((config: HardhatConfig, userConfig: Readonly<HardhatUserConfig>) => {
	// Source for the path convention:
	// https://github.com/NomicFoundation/hardhat-ts-plugin-boilerplate/blob/d450d89f4b6ed5d26a8ae32b136b9c55d2aadab5/src/index.ts
	const userPath = userConfig.paths?.bards

	let newPath: string
	if (userPath === undefined) {
		newPath = config.paths.root
	} else {
		if (path.isAbsolute(userPath)) {
			newPath = userPath
		} else {
			newPath = path.normalize(path.join(config.paths.root, userPath))
		}
	}

	config.paths.bards = newPath
})

extendEnvironment((hre: HardhatRuntimeEnvironment) => {
	hre.bards = (opts: BardsRuntimeEnvironmentOptions = {}) => {
		logDebug('*** Initializing Bards Runtime Environment (BRE) ***')
		logDebug(`Main network: ${hre.network.name}`)
		const { l1ChainId, l2ChainId, isHHL1 } = getChains(hre.network.config.chainId)
		const { l1Provider, l2Provider } = getProviders(hre, l1ChainId, l2ChainId, isHHL1)
		const addressBookPath = getAddressBookPath(hre, opts)
		const { l1BardsConfigPath, l2BardsConfigPath } = getBardsConfigPaths(
			hre,
			opts,
			l1ChainId,
			l2ChainId,
			isHHL1,
		)

		// Wallet functions
		const l1GetWallets = () => getWallets(hre.config.networks, l1ChainId, hre.network.name)
		const l1GetWallet = (address: string) =>
			getWallet(hre.config.networks, l1ChainId, hre.network.name, address)
		const l2GetWallets = () => getWallets(hre.config.networks, l2ChainId, hre.network.name)
		const l2GetWallet = (address: string) =>
			getWallet(hre.config.networks, l2ChainId, hre.network.name, address)

		// Build the Bards Runtime Environment (BRE)
		const l1Bards: BardsNetworkEnvironment | null = buildBardsNetworkEnvironment(
			l1ChainId,
			l1Provider,
			l1BardsConfigPath,
			addressBookPath,
			isHHL1,
			l1GetWallets,
			l1GetWallet,
		)

		const l2Bards: BardsNetworkEnvironment | null = buildBardsNetworkEnvironment(
			l2ChainId,
			l2Provider,
			l2BardsConfigPath,
			addressBookPath,
			isHHL1,
			l2GetWallets,
			l2GetWallet,
		)

		const bre: BardsRuntimeEnvironment = {
			...(isHHL1 ? (l1Bards as BardsNetworkEnvironment) : (l2Bards as BardsNetworkEnvironment)),
			l1: l1Bards,
			l2: l2Bards,
		}

		logDebug('BRE initialized successfully!')
		logDebug(`Main network: L${isHHL1 ? '1' : '2'}`)
		logDebug(`Secondary network: ${bre.l2 !== null ? (isHHL1 ? 'L2' : 'L1') : 'not initialized'}`)
		return bre
	}
})

function buildBardsNetworkEnvironment(
	chainId: number,
	provider: EthersProviderWrapper | undefined,
	bardsConfigPath: string | undefined,
	addressBookPath: string,
	isHHL1: boolean,
	getWallets: () => Promise<Wallet[]>,
	getWallet: (address: string) => Promise<Wallet>,
): BardsNetworkEnvironment | null {
	if (bardsConfigPath === undefined) {
		logWarn(
			`No bards config file provided for chain: ${chainId}. ${isHHL1 ? 'L2' : 'L1'
			} will not be initialized.`,
		)
		return null
	}

	if (provider === undefined) {
		logWarn(
			`No provider URL found for: ${chainId}. ${isHHL1 ? 'L2' : 'L1'} will not be initialized.`,
		)
		return null
	}

	return {
		chainId: chainId,
		provider: provider,
		addressBook: lazyObject(() => getAddressBook(addressBookPath, chainId.toString())),
		bardsConfig: lazyObject(() => readConfig(bardsConfigPath, true)),
		contracts: lazyObject(() =>
			loadContracts(getAddressBook(addressBookPath, chainId.toString()), provider),
		),
		getDeployer: lazyFunction(() => () => getDeployer(provider)),
		getNamedAccounts: lazyFunction(() => () => getNamedAccounts(provider, bardsConfigPath)),
		getTestAccounts: lazyFunction(() => () => getTestAccounts(provider, bardsConfigPath)),
		getWallets: lazyFunction(() => () => getWallets()),
		getWallet: lazyFunction(() => (address: string) => getWallet(address)),
	}
}