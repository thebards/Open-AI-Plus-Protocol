import fs from 'fs'
import path from 'path'

import { NetworkConfig, NetworksConfig } from 'hardhat/types/config'
import { HardhatRuntimeEnvironment } from 'hardhat/types/runtime'
import { HttpNetworkConfig } from 'hardhat/types/config'

import { BardsRuntimeEnvironmentOptions } from './typeExtensions'
import { BREPluginError } from './helpers/error'
import BardsNetwork, { counterpartName } from './helpers/network'

import { createProvider } from 'hardhat/internal/core/providers/construction'
import { EthersProviderWrapper } from '@nomiclabs/hardhat-ethers/internal/ethers-provider-wrapper'

import { logDebug, logWarn } from './logger'
import { HARDHAT_NETWORK_NAME } from 'hardhat/plugins'

interface BREChains {
	l1ChainId: number
	l2ChainId: number
	isHHL1: boolean
	isHHL2: boolean
}

interface BREProviders {
	l1Provider: EthersProviderWrapper | undefined
	l2Provider: EthersProviderWrapper | undefined
}

interface BREBardsConfigs {
	l1BardsConfigPath: string | undefined
	l2BardsConfigPath: string | undefined
}

export function getAddressBookPath(
	hre: HardhatRuntimeEnvironment,
	opts: BardsRuntimeEnvironmentOptions,
): string {
	logDebug('== Getting address book path')
	logDebug(`Bards base dir: ${hre.config.paths.bards}`)
	logDebug(`1) opts.addressBookPath: ${opts.addressBook}`)
	logDebug(`2) hre.config.bards.addressBook: ${hre.config.bards?.addressBook}`)

	let addressBookPath = opts.addressBook ?? hre.config.bards?.addressBook

	if (addressBookPath === undefined) {
		throw new BREPluginError('Must set a an addressBook path!')
	}

	addressBookPath = normalizePath(addressBookPath, hre.config.paths.bards!)

	if (!fs.existsSync(addressBookPath)) {
		throw new BREPluginError(`Address book not found: ${addressBookPath}`)
	}

	logDebug(`Address book path found: ${addressBookPath}`)
	return addressBookPath
}

export function getChains(mainChainId: number | undefined): BREChains {
	logDebug('== Getting chain ids')
	logDebug(`Hardhat chain id: ${mainChainId}`)

	if (!BardsNetwork.isSupported(mainChainId)) {
		throw new BREPluginError(`Chain ${mainChainId} is not supported!`)
	}

	// If mainChainId is supported there is a supported counterpart chainId so both chains are not undefined
	// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
	mainChainId = mainChainId!

	// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
	const secondaryChainId = BardsNetwork.counterpart(mainChainId)!
	logDebug(`Secondary chain id: ${secondaryChainId}`)

	const isHHL1 = BardsNetwork.isL1(mainChainId)
	const isHHL2 = BardsNetwork.isL2(mainChainId)
	const l1ChainId = isHHL1 ? mainChainId : secondaryChainId
	const l2ChainId = isHHL2 ? mainChainId : secondaryChainId

	logDebug(`L1 chain id: ${l1ChainId} - Is HHL1: ${isHHL1}`)
	logDebug(`L2 chain id: ${l2ChainId} - Is HHL2: ${isHHL2}`)

	return {
		l1ChainId,
		l2ChainId,
		isHHL1,
		isHHL2,
	}
}

export function getProviders(
	hre: HardhatRuntimeEnvironment,
	l1ChainId: number,
	l2ChainId: number,
	isHHL1: boolean,
): BREProviders {
	logDebug('== Getting providers')

	const getProvider = (
		networks: NetworksConfig,
		chainId: number,
		mainNetworkName: string,
		isMainProvider: boolean,
		chainLabel: string,
	): EthersProviderWrapper | undefined => {
		const network = getNetworkConfig(networks, chainId, mainNetworkName) as HttpNetworkConfig
		const networkName = getNetworkName(networks, chainId, mainNetworkName)

		logDebug(`Provider url for ${chainLabel}(${networkName}): ${network?.url}`)

		// Ensure at least main provider is configured
		// For Hardhat network we don't need url to create a provider
		if (
			isMainProvider &&
			(network === undefined || network.url === undefined) &&
			networkName !== HARDHAT_NETWORK_NAME
		) {
			throw new BREPluginError(`Must set a provider url for chain: ${chainId}!`)
		}

		if (network === undefined || networkName === undefined) {
			return undefined
		}

		// Build provider as EthersProviderWrapper instead of JsonRpcProvider
		// This allows us to use hardhat's account management methods for free
		const ethereumProvider = createProvider(networkName, network)
		const ethersProviderWrapper = new EthersProviderWrapper(ethereumProvider)
		return ethersProviderWrapper
	}

	const l1Provider = getProvider(hre.config.networks, l1ChainId, hre.network.name, isHHL1, 'L1')
	const l2Provider = getProvider(hre.config.networks, l2ChainId, hre.network.name, !isHHL1, 'L2')

	return {
		l1Provider,
		l2Provider,
	}
}

export function getBardsConfigPaths(
	hre: HardhatRuntimeEnvironment,
	opts: BardsRuntimeEnvironmentOptions,
	l1ChainId: number,
	l2ChainId: number,
	isHHL1: boolean,
): BREBardsConfigs {
	logDebug('== Getting bards config paths')
	logDebug(`Bards base dir: ${hre.config.paths.bards}`)

	const l1Network = getNetworkConfig(hre.config.networks, l1ChainId, hre.network.name)
	const l2Network = getNetworkConfig(hre.config.networks, l2ChainId, hre.network.name)

	// Priority is as follows:
	// - hre.bards() init parameter l1BardsConfigPath/l2BardsConfigPath
	// - hre.bards() init parameter bardsConfigPath (only for layer corresponding to hh network)
	// - hh network config
	// - hh bards config (layer specific: l1BardsConfig, l2BardsConfig)
	let l1BardsConfigPath =
		opts.l1BardsConfig ??
		(isHHL1 ? opts.bardsConfig : undefined) ??
		l1Network?.bardsConfig ??
		hre.config.bards.l1BardsConfig

	logDebug(`> L1 bards config`)
	logDebug(`1) opts.l1BardsConfig: ${opts.l1BardsConfig}`)
	logDebug(`2) opts.bardsConfig: ${isHHL1 ? opts.bardsConfig : undefined}`)
	logDebug(`3) l1Network.bardsConfig: ${l1Network?.bardsConfig}`)
	logDebug(`4) hre.config.bards.l1BardsConfig: ${hre.config.bards.l1BardsConfig}`)

	if (isHHL1 && l1BardsConfigPath === undefined) {
		throw new BREPluginError('Must specify a bards config file for L1!')
	}

	if (l1BardsConfigPath !== undefined) {
		l1BardsConfigPath = normalizePath(l1BardsConfigPath, hre.config.paths.bards!)
	}

	let l2BardsConfigPath =
		opts.l2BardsConfig ??
		(!isHHL1 ? opts.bardsConfig : undefined) ??
		l2Network?.bardsConfig ??
		hre.config.bards.l2BardsConfig

	logDebug(`> L2 bards config`)
	logDebug(`1) opts.l2BardsConfig: ${opts.l2BardsConfig}`)
	logDebug(`2) opts.bardsConfig: ${!isHHL1 ? opts.bardsConfig : undefined}`)
	logDebug(`3) l2Network.bardsConfig: ${l2Network?.bardsConfig}`)
	logDebug(`4) hre.config.bards.l2BardsConfig: ${hre.config.bards.l2BardsConfig}`)

	if (!isHHL1 && l2BardsConfigPath === undefined) {
		throw new BREPluginError('Must specify a bards config file for L2!')
	}

	if (l2BardsConfigPath !== undefined) {
		l2BardsConfigPath = normalizePath(l2BardsConfigPath, hre.config.paths.bards!)
	}

	for (const configPath of [l1BardsConfigPath, l2BardsConfigPath]) {
		if (configPath !== undefined && !fs.existsSync(configPath)) {
			throw new BREPluginError(`Bards config file not found: ${configPath}`)
		}
	}

	logDebug(`L1 bards config path: ${l1BardsConfigPath}`)
	logDebug(`L2 bards config path: ${l2BardsConfigPath}`)

	return {
		l1BardsConfigPath: l1BardsConfigPath,
		l2BardsConfigPath: l2BardsConfigPath,
	}
}

function getNetworkConfig(
	networks: NetworksConfig,
	chainId: number,
	mainNetworkName: string,
): (NetworkConfig & { name: string }) | undefined {
	const candidateNetworks = Object.keys(networks)
		.map((n) => ({ ...networks[n], name: n }))
		.filter((n) => n.chainId === chainId)

	if (candidateNetworks.length > 1) {
		logWarn(
			`Found multiple networks with chainId ${chainId}, trying to use main network name to desambiguate`,
		)

		const filteredByMainNetworkName = candidateNetworks.filter((n) => n.name === mainNetworkName)

		if (filteredByMainNetworkName.length === 1) {
			logDebug(`Found network with chainId ${chainId} and name ${mainNetworkName}`)
			return filteredByMainNetworkName[0]
		} else {
			logWarn(`Could not desambiguate with main network name, trying secondary network name`)
			const secondaryNetworkName = counterpartName(mainNetworkName)
			const filteredBySecondaryNetworkName = candidateNetworks.filter(
				(n) => n.name === secondaryNetworkName,
			)

			if (filteredBySecondaryNetworkName.length === 1) {
				logDebug(`Found network with chainId ${chainId} and name ${mainNetworkName}`)
				return filteredBySecondaryNetworkName[0]
			} else {
				throw new BREPluginError(
					`Could not desambiguate network with chainID ${chainId}. Use case not supported!`,
				)
			}
		}
	} else if (candidateNetworks.length === 1) {
		return candidateNetworks[0]
	} else {
		return undefined
	}
}

export function getNetworkName(
	networks: NetworksConfig,
	chainId: number,
	mainNetworkName: string,
): string | undefined {
	const network = getNetworkConfig(networks, chainId, mainNetworkName)
	return network?.name
}

function normalizePath(_path: string, bardsPath: string) {
	if (!path.isAbsolute(_path)) {
		_path = path.join(bardsPath, _path)
	}
	return _path
}