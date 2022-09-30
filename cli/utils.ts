import { Contract, Wallet, providers } from 'ethers'
import { BigNumber, BigNumberish } from 'ethers'
import { parseUnits, formatUnits } from 'ethers/lib/utils'
import { loadArtifact } from './artifacts'

export const contractAt = (
	contractName: string,
	contractAddress: string,
	wallet: Wallet,
): Contract => {
	return new Contract(contractAddress, loadArtifact(contractName).abi, wallet.provider)
}

export const getProvider = (providerUrl: string, network?: number): providers.JsonRpcProvider =>
	new providers.JsonRpcProvider(providerUrl, network)

export const formatGRT = (value: BigNumberish): string => formatUnits(value, 18)

export const parseGRT = (grt: string): BigNumber => parseUnits(grt, 18)