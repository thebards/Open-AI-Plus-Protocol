import hre, { ethers } from 'hardhat';
import { providers, utils, BigNumber, Signer, Wallet, BigNumberish } from 'ethers'
import { formatUnits, getAddress } from 'ethers/lib/utils'
import { expect } from 'chai';

import { 
	BARDS_HUB_NFT_NAME, 
	HARDHAT_CHAINID, 
	DOMAIN_SALT,
	MAX_UINT256
} from "./Constants";

import {
	eventsLib,
	bardsHub,
	testWallet,
	user,
} from '../__setup.test';

import { 
	BardsHub__factory 
} from '../../typechain-types';

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

export async function cancelWithPermitForAll(nft: string = bardsHub.address) {
	const nftContract = BardsHub__factory.connect(nft, testWallet);
	const name = await nftContract.name();
	const nonce = (await nftContract.sigNonces(testWallet.address)).toNumber();
	const { v, r, s } = await getPermitForAllParts(
		nft,
		name,
		testWallet.address,
		testWallet.address,
		false,
		nonce,
		MAX_UINT256
	);

	await nftContract.permitForAll(
		testWallet.address, 
		testWallet.address, 
		false, 
		{
			v,
			r,
			s,
			deadline: MAX_UINT256
		}
	);
}

export async function getPermitForAllParts(
	nft: string,
	name: string,
	owner: string,
	operator: string,
	approved: boolean,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildPermitForAllParams(
		nft, 
		name, 
		owner, 
		operator, 
		approved, 
		nonce, 
		deadline
	);
	return await getSig(msgParams);
}

const buildPermitForAllParams = (
	nft: string,
	name: string,
	owner: string,
	operator: string,
	approved: boolean,
	nonce: number,
	deadline: string
) => ({
	types: {
		PermitForAll: [
			{ name: 'owner', type: 'address' },
			{ name: 'operator', type: 'address' },
			{ name: 'approved', type: 'bool' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: {
		name: name,
		version: '1',
		chainId: getChainId(),
		verifyingContract: nft,
		salt: DOMAIN_SALT
	},
	value: {
		owner: owner,
		operator: operator,
		approved: approved,
		nonce: nonce,
		deadline: deadline,
	},
});

export async function getSetDefaultProfileWithSigParts(
	wallet: string,
	profileId: BigNumberish,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildSetDefaultProfileWithSigParams(
		profileId, 
		wallet, 
		nonce, 
		deadline
	);
	return await getSig(msgParams);
}

const buildSetDefaultProfileWithSigParams = (
	profileId: BigNumberish,
	wallet: string,
	nonce: number,
	deadline: string
) => ({
	types: {
		SetDefaultProfileWithSig: [
			{ name: 'wallet', type: 'address' },
			{ name: 'profileId', type: 'uint256' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		wallet: wallet,
		profileId: profileId,
		nonce: nonce,
		deadline: deadline,
	},
});


async function getSig(msgParams: {
	domain: any;
	types: any;
	value: any;
}): Promise<{ v: number; r: string; s: string }> {
	const sig = await testWallet._signTypedData(
		msgParams.domain, 
		msgParams.types, 
		msgParams.value
	);
	return utils.splitSignature(sig);
}

function domain(): { 
	name: string; 
	version: string; 
	chainId: number; 
	verifyingContract: string,
	salt: string
} {
	return {
		name: BARDS_HUB_NFT_NAME,
		version: '1',
		chainId: getChainId(),
		verifyingContract: bardsHub.address,
		salt: DOMAIN_SALT
	};
}