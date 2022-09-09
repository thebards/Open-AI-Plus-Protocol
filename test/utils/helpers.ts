import hre, { ethers } from 'hardhat';
import { providers, utils, BigNumber, Signer, Wallet, BigNumberish, Bytes } from 'ethers'
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
	CurationType
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

export async function getCreateCurationWithSigParts(
	profileId: BigNumberish,
	tokenContractPointed: string,
	tokenIdPointed: BigNumberish,
	contentURI: string,
	marketModule: string,
	marketModuleInitData: Bytes | string,
	minterMarketModule: string,
	minterMarketModuleInitData: Bytes | string,
	curationMetaData: Bytes | string,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildCreateCurationWithSigParams(
		profileId,
		tokenContractPointed,
		tokenIdPointed,
		contentURI,
		marketModule,
		marketModuleInitData,
		minterMarketModule,
		minterMarketModuleInitData,
		curationMetaData,
		nonce,
		deadline
	);
	return await getSig(msgParams);
}

export async function getSetCurationContentURIWithSigParts(
	curationId: BigNumberish,
	contentURI: string,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildSetCurationContentURIWithSigParams(
		curationId, 
		contentURI, 
		nonce, 
		deadline
	);
	return await getSig(msgParams);
}

const buildSetCurationContentURIWithSigParams = (
	curationId: BigNumberish,
	contentURI: string,
	nonce: number,
	deadline: string
) => ({
	types: {
		SetCurationContentURIWithSig: [
			{ name: 'curationId', type: 'uint256' },
			{ name: 'contentURI', type: 'string' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		curationId: curationId,
		contentURI: contentURI,
		nonce: nonce,
		deadline: deadline
	},
});

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
		deadline: deadline
	},
});

const buildCreateCurationWithSigParams = (
	profileId: BigNumberish,
	tokenContractPointed: string,
	tokenIdPointed: BigNumberish,
	contentURI: string,
	marketModule: string,
	marketModuleInitData: Bytes | string,
	minterMarketModule: string,
	minterMarketModuleInitData: Bytes | string,
	curationMetaData: Bytes | string,
	nonce: number,
	deadline: string
) => ({
	types: {
		CreateCurationWithSig: [
			{ name: 'profileId', type: 'uint256' },
			{ name: 'tokenContractPointed', type: 'address' },
			{ name: 'tokenIdPointed', type: 'uint256' },
			{ name: 'contentURI', type: 'string' },
			{ name: 'marketModule', type: 'address' },
			{ name: 'marketModuleInitData', type: 'bytes' },
			{ name: 'minterMarketModule', type: 'address' },
			{ name: 'minterMarketModuleInitData', type: 'bytes' },
			{ name: 'curationMetaData', type: 'bytes' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		profileId: profileId,
		tokenContractPointed: tokenContractPointed,
		tokenIdPointed: tokenIdPointed,
		contentURI: contentURI,
		marketModule: marketModule,
		marketModuleInitData: marketModuleInitData,
		minterMarketModule: minterMarketModule,
		minterMarketModuleInitData: minterMarketModuleInitData,
		curationMetaData: curationMetaData,
		nonce: nonce,
		deadline: deadline,
	},
});

export async function getSetMarketModuleWithSigParts(
	curationId: BigNumberish,
	tokenContract: string,
	tokenId: number,
	marketModule: string,
	marketModuleInitData: Bytes | string,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildSetMarketModuleWithSigParams(
		curationId,
		tokenContract,
		tokenId,
		marketModule,
		marketModuleInitData,
		nonce,
		deadline
	);
	return await getSig(msgParams);
}

const buildSetMarketModuleWithSigParams = (
	curationId: BigNumberish,
	tokenContract: string,
	tokenId: number,
	marketModule: string,
	marketModuleInitData: Bytes | string,
	nonce: number,
	deadline: string
) => ({
	types: {
		SetMarketModuleWithSig: [
			{ name: 'curationId', type: 'uint256' },
			{ name: 'tokenContract', type: 'address' },
			{ name: 'tokenId', type: 'uint256' },
			{ name: 'marketModule', type: 'address' },
			{ name: 'marketModuleInitData', type: 'bytes' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		curationId: curationId,
		tokenContract: tokenContract,
		tokenId: tokenId,
		marketModule: marketModule,
		marketModuleInitData: marketModuleInitData,
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

// Allocation keys

interface ChannelKey {
	privKey: string
	pubKey: string
	address: string
	wallet: Signer
	generateProof: (address) => Promise<string>
}

export const deriveChannelKey = (): ChannelKey => {
	const w = Wallet.createRandom()
	return {
		privKey: w.privateKey,
		pubKey: w.publicKey,
		address: w.address,
		wallet: w,
		generateProof: (curatorAddress: string): Promise<string> => {
			const messageHash = utils.solidityKeccak256(
				['address', 'address'],
				[curatorAddress, w.address],
			)
			const messageHashBytes = utils.arrayify(messageHash)
			return w.signMessage(messageHashBytes)
		},
	}
}