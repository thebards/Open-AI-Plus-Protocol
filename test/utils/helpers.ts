import hre, { ethers } from 'hardhat';
import { providers, utils, BigNumber, Signer, Wallet } from 'ethers'
import { formatUnits, getAddress } from 'ethers/lib/utils'
import { expect } from 'chai';
import { HARDHAT_CHAINID } from "./Constants";
import {
	eventsLib,
	bardsHub,
	testWallet,
	user,
} from '../__setup.test';

import { 
	DataTypes
} from "../../typechain-types/contracts/core/BardsHub";


const { hexlify, parseUnits, randomBytes } = utils


export const toBN = (value: string | number): BigNumber => BigNumber.from(value)
export const toBCT = (value: string | number): BigNumber => {
	return parseUnits(typeof value === 'number' ? value.toString() : value, '18')
}
export const formatBCT = (value: BigNumber): string => formatUnits(value, '18')
export const randomHexBytes = (n = 32): string => hexlify(randomBytes(n))
export const randomAddress = (): string => getAddress(randomHexBytes(20))

let snapshotId: string = '0x1';
export async function takeSnapshot() {
	snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
	await hre.ethers.provider.send('evm_revert', [snapshotId]);
}

export function getChainId(): number {
	return hre.network.config.chainId || HARDHAT_CHAINID;
}

export async function getTimestamp(): Promise<any> {
	const blockNumber = await hre.ethers.provider.send('eth_blockNumber', []);
	const block = await hre.ethers.provider.send('eth_getBlockByNumber', [blockNumber, false]);
	return block.timestamp;
}

export interface CreateProfileReturningTokenIdStruct {
	sender?: Signer;
	vars: DataTypes.CreateCurationDataStruct;
}

export async function createProfileReturningTokenId({
	sender = user,
	vars,
}: CreateProfileReturningTokenIdStruct): Promise<BigNumber> {
	const tokenId = await bardsHub.connect(sender).callStatic.createProfile(vars);
	await expect(bardsHub.connect(sender).createProfile(vars)).to.not.be.reverted;
	return tokenId;
}