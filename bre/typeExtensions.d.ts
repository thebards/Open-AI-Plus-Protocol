import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { AddressBook } from '../cli/addressBook'
import { NetworkContracts } from '../cli/contracts'

import { EthersProviderWrapper } from '@nomiclabs/hardhat-ethers/internal/ethers-provider-wrapper'
import { Wallet } from 'ethers'

export interface BardsRuntimeEnvironmentOptions {
	addressBook?: string
	l1BardsConfig?: string
	l2BardsConfig?: string
	bardsConfig?: string
}

export type AccountNames =
	| 'governor'
	| 'treasury'
	| 'stakingTreasury'
	| 'proxyAdmin'

export type NamedAccounts = {
	[name in AccountNames]: SignerWithAddress
}

export interface BardsNetworkEnvironment {
	chainId: number
	provider: EthersProviderWrapper
	contracts: NetworkContracts
	bardsConfig: any
	addressBook: AddressBook
	getNamedAccounts: () => Promise<NamedAccounts>
	getTestAccounts: () => Promise<SignerWithAddress[]>
	getDeployer: () => Promise<SignerWithAddress>
	getWallets: () => Promise<Wallet[]>
	getWallet: (address: string) => Promise<Wallet>
}

export interface BardsRuntimeEnvironment extends BardsNetworkEnvironment {
	l1: BardsNetworkEnvironment | null
	l2: BardsNetworkEnvironment | null
}

declare module 'hardhat/types/runtime' {
	export interface HardhatRuntimeEnvironment {
		bards: (opts?: BardsRuntimeEnvironmentOptions) => BardsRuntimeEnvironment
	}
}

declare module 'hardhat/types/config' {
	export interface HardhatConfig {
		bards: Omit<BardsRuntimeEnvironmentOptions, 'bardsConfig'>
	}

	export interface HardhatUserConfig {
		bards: Omit<BardsRuntimeEnvironmentOptions, 'bardsConfig'>
	}

	export interface HardhatNetworkConfig {
		bardsConfig?: string
	}

	export interface HardhatNetworkUserConfig {
		bardsConfig?: string
	}

	export interface HttpNetworkConfig {
		bardsConfig?: string
	}

	export interface HttpNetworkUserConfig {
		bardsConfig?: string
	}

	export interface ProjectPathsConfig {
		bards?: string
	}

	export interface ProjectPathsUserConfig {
		bards?: string
	}
}