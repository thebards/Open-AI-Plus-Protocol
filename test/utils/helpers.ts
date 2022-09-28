import hre, { ethers } from 'hardhat';
import { providers, utils, BigNumber, Signer, Wallet, Contract, BigNumberish, Bytes, logger } from 'ethers'
import { BytesLike, keccak256, RLP, toUtf8Bytes, formatUnits, getAddress } from 'ethers/lib/utils';
import { expect } from 'chai';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';

import { 
	BARDS_HUB_NFT_NAME, 
	BARDS_CURATION_TOKEN_NAME,
	HARDHAT_CHAINID, 
	DOMAIN_SALT,
	MAX_UINT256,
	BPS_MAX
} from "./Constants";

import {
	eventsLib,
	bardsHub,
	testWallet,
	user,
	CurationType,
	bardsCurationToken,
	bardsStaking,
	userTwoAddress
} from '../__setup.test';

import { 
	BardsHub__factory, BardsStaking 
} from '../../typechain-types';

import { 
	DataTypes
} from "../../typechain-types/contracts/core/BardsHub";

import { 
	EpochManager 
} from '../../typechain-types/contracts/core/govs/EpochManager';
import { Address } from 'defender-relay-client';


const { hexlify, parseUnits, randomBytes } = utils

export const toBN = (value: string | number): BigNumber => BigNumber.from(value)
export const toBCT = (value: string | number): BigNumber => {
	return parseUnits(typeof value === 'number' ? value.toString() : value, '18')
}
export const formatBCT = (value: BigNumber): string => formatUnits(value, '18')
export const randomHexBytes = (n = 32): string => hexlify(randomBytes(n))
export const randomAddress = (): string => getAddress(randomHexBytes(20))
export const toFloat = (n: BigNumber) => parseFloat(formatBCT(n));
export const toRound = (n: number) => n.toFixed(12)
export const toFixed = (n: number | BigNumber, precision = 12) => {
	if (typeof n === 'number') {
		return n.toFixed(precision)
	}
	return toFloat(n).toFixed(precision)
}

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

export async function waitForTx(
	tx: Promise<TransactionResponse> | TransactionResponse,
	skipCheck = false
): Promise<TransactionReceipt> {
	if (!skipCheck) await expect(tx).to.not.be.reverted;
	return await (await tx).wait();
}

export function matchEvent(
	receipt: TransactionReceipt,
	name: string,
	expectedArgs?: any[],
	eventContract: Contract = eventsLib,
	emitterAddress?: string
) {
	const events = receipt.logs;

	if (events != undefined) {
		// match name from list of events in eventContract, when found, compute the sigHash
		let sigHash: string | undefined;
		for (let contractEvent of Object.keys(eventContract.interface.events)) {
			if (contractEvent.startsWith(name) && contractEvent.charAt(name.length) == '(') {
				sigHash = keccak256(toUtf8Bytes(contractEvent));
				break;
			}
		}
		// Throw if the sigHash was not found
		if (!sigHash) {
			logger.throwError(
				`Event "${name}" not found in provided contract (default: Events libary). \nAre you sure you're using the right contract?`
			);
		}

		// Find the given event in the emitted logs
		let invalidParamsButExists = false;
		for (let emittedEvent of events) {
			// If we find one with the correct sighash, check if it is the one we're looking for
			if (emittedEvent.topics[0] == sigHash) {
				// If an emitter address is passed, validate that this is indeed the correct emitter, if not, continue
				if (emitterAddress) {
					if (emittedEvent.address != emitterAddress) continue;
				}
				const event = eventContract.interface.parseLog(emittedEvent);
				// If there are expected arguments, validate them, otherwise, return here
				if (expectedArgs) {
					if (expectedArgs.length != event.args.length) {
						logger.throwError(
							`Event "${name}" emitted with correct signature, but expected args are of invalid length`
						);
					}
					invalidParamsButExists = false;
					// Iterate through arguments and check them, if there is a mismatch, continue with the loop
					for (let i = 0; i < expectedArgs.length; i++) {
						// Parse empty arrays as empty bytes
						if (expectedArgs[i].constructor == Array && expectedArgs[i].length == 0) {
							expectedArgs[i] = '0x';
						}

						// Break out of the expected args loop if there is a mismatch, this will continue the emitted event loop
						if (BigNumber.isBigNumber(event.args[i])) {
							if (!event.args[i].eq(BigNumber.from(expectedArgs[i]))) {
								invalidParamsButExists = true;
								break;
							}
						} else if (event.args[i].constructor == Array) {
							let params = event.args[i];
							let expected = expectedArgs[i];
							if (expected != '0x' && params.length != expected.length) {
								invalidParamsButExists = true;
								break;
							}
							for (let j = 0; j < params.length; j++) {
								if (BigNumber.isBigNumber(params[j])) {
									if (!params[j].eq(BigNumber.from(expected[j]))) {
										invalidParamsButExists = true;
										break;
									}
								} else if (params[j] != expected[j]) {
									invalidParamsButExists = true;
									break;
								}
							}
							if (invalidParamsButExists) break;
						} else if (event.args[i] != expectedArgs[i]) {
							invalidParamsButExists = true;
							break;
						}
					}
					// Return if the for loop did not cause a break, so a match has been found, otherwise proceed with the event loop
					if (!invalidParamsButExists) {
						return;
					}
				} else {
					return;
				}
			}
		}
		// Throw if the event args were not expected or the event was not found in the logs
		if (invalidParamsButExists) {
			logger.throwError(`Event "${name}" found in logs but with unexpected args`);
		} else {
			logger.throwError(
				`Event "${name}" not found emitted by "${emitterAddress}" in given transaction log`
			);
		}
	} else {
		logger.throwError('No events were emitted');
	}
}

export async function getTimestamp(): Promise<any> {
	const blockNumber = await hre.ethers.provider.send('eth_blockNumber', []);
	const block = await hre.ethers.provider.send('eth_getBlockByNumber', [blockNumber, false]);
	return block.timestamp;
}

export const provider = (): providers.JsonRpcProvider => hre.ethers.provider

export const latestBlock = (): Promise<BigNumber> =>
	provider().send('eth_blockNumber', []).then(toBN)

export const advanceBlock = (): Promise<void> => {
	return provider().send('evm_mine', [])
}

export const advanceBlockTo = async (blockNumber: string | number | BigNumber): Promise<void> => {
	const target =
		typeof blockNumber === 'number' || typeof blockNumber === 'string'
			? toBN(blockNumber)
			: blockNumber
	const currentBlock = await latestBlock()
	const start = Date.now()
	let notified
	if (target.lt(currentBlock))
		throw Error(`Target block #(${target}) is lower than current block #(${currentBlock})`)
	while ((await latestBlock()).lt(target)) {
		if (!notified && Date.now() - start >= 5000) {
			notified = true
			console.log(`advanceBlockTo: Advancing too ` + 'many blocks is causing this test to be slow.')
		}
		await advanceBlock()
	}
}

export const advanceBlocks = async (blocks: string | number | BigNumber) => {
	const steps = typeof blocks === 'number' || typeof blocks === 'string' ? toBN(blocks) : blocks
	const currentBlock = await latestBlock()
	const toBlock = currentBlock.add(steps)
	await advanceBlockTo(toBlock)
}

export const advanceToNextEpoch = async (epochManager: EpochManager): Promise<void> => {
	const currentBlock = await latestBlock()
	const epochLength = await epochManager.epochLength()
	const nextEpochBlock = currentBlock.add(epochLength)
	await advanceBlockTo(nextEpochBlock)
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

export async function getSetAllocationIdWithSigParts(
	curationId: BigNumberish,
	allocationId: BigNumberish,
	curationMetaData: Bytes | string,
	stakeToCuration: BigNumberish,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildSetAllocationIdWithSigParams(
		curationId,
		allocationId,
		curationMetaData,
		stakeToCuration,
		nonce,
		deadline
	);
	return await getSig(msgParams);
}

export async function getCollectWithSigParts(
	curationId: BigNumberish,
	collectMetaData: Bytes | string,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildCollectWithSigParams(
		curationId, 
		collectMetaData,
		nonce, 
		deadline
	);
	return await getSig(msgParams);
}

export async function getBCTPermitWithSigParts(
	owner: string,
	spender: string,
	value: BigNumberish,
	nonce: number,
	deadline: string
): Promise<{ v: number; r: string; s: string }> {
	const msgParams = buildBCTPermitWithSigParams(
		owner,
		spender,
		value,
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
	curationFrom: BigNumberish,
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
		curationFrom,
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

const buildBCTPermitWithSigParams = (
	owner: string,
	spender: string,
	value: BigNumberish,
	nonce: number,
	deadline: string
) => ({
	types: {
		Permit: [
			{ name: 'owner', type: 'address' },
			{ name: 'spender', type: 'address' },
			{ name: 'value', type: 'uint256' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' }
		],
	},
	domain: BCTDomain(),
	value: {
		owner: owner,
		spender: spender,
		value: value,
		nonce: nonce,
		deadline: deadline
	},
});

const buildCollectWithSigParams = (
	curationId: BigNumberish,
	collectMetaData: Bytes | string,
	nonce: number,
	deadline: string
) => ({
	types: {
		CollectWithSig: [
			{ name: 'curationId', type: 'uint256' },
			{ name: 'collectMetaData', type: 'bytes' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		curationId: curationId,
		collectMetaData: collectMetaData,
		nonce: nonce,
		deadline: deadline,
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

const buildSetAllocationIdWithSigParams = (
	curationId: BigNumberish,
	allocationId: BigNumberish,
	curationMetaData: Bytes | string,
	stakeToCuration: BigNumberish,
	nonce: number,
	deadline: string
) => ({
	types: {
		SetAllocationIdWithSig: [
			{ name: 'curationId', type: 'uint256' },
			{ name: 'allocationId', type: 'uint256' },
			{ name: 'curationMetaData', type: 'bytes' },
			{ name: 'stakeToCuration', type: 'uint256' },
			{ name: 'nonce', type: 'uint256' },
			{ name: 'deadline', type: 'uint256' },
		],
	},
	domain: domain(),
	value: {
		curationId: curationId,
		allocationId: allocationId,
		curationMetaData: curationMetaData,
		stakeToCuration: stakeToCuration,
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
	curationFrom: BigNumberish,
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
			// { name: 'curationFrom', type: 'uint256' },
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
		// curationFrom: curationFrom,
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

function BCTDomain(): {
	name: string;
	version: string;
	chainId: number;
	verifyingContract: string,
	salt: string
} {
	return {
		name: BARDS_CURATION_TOKEN_NAME,
		version: '1',
		chainId: getChainId(),
		verifyingContract: bardsCurationToken.address,
		salt: DOMAIN_SALT
	};
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

export interface CollectReturningPairStruct {
	sender?: Signer;
	vars: DataTypes.SimpleDoCollectDataStruct | DataTypes.DoCollectWithSigDataStruct;
}

export async function collectReturningTokenPair({
	sender = user,
	vars,
}: CollectReturningPairStruct): Promise<[string, BigNumber]> {
	let tokenPair: [string, BigNumber];
	if ('sig' in vars) {
		tokenPair = await bardsHub
			.connect(sender)
			.callStatic.collectWithSig(vars);
		await expect(bardsHub.connect(sender).collectWithSig(vars)).to.not.be.reverted;
	} else {
		tokenPair = await bardsHub
			.connect(sender)
			.callStatic.collect(vars);
		await expect(bardsHub.connect(sender).collect(vars)).to.not.be.reverted;
	}
	return tokenPair;
}

export async function approveToken(
	spender: string,
	tokensToApprove: BigNumber
){
	const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

	const { v, r, s } = await getBCTPermitWithSigParts(
		testWallet.address,
		spender,
		tokensToApprove,
		nonce,
		MAX_UINT256
	);

	await bardsCurationToken.callStatic.permit({
		owner: testWallet.address,
		spender: spender,
		value: tokensToApprove,
		sig: {
			v,
			r,
			s,
			deadline: MAX_UINT256
		},
	})

	await expect(
		bardsCurationToken.permit({
			owner: testWallet.address,
			spender: spender,
			value: tokensToApprove,
			sig: {
				v,
				r,
				s,
				deadline: MAX_UINT256
			},
		})
	).to.not.be.reverted;
}

export async function calcBondingCurve(
	supply: BigNumber,
	reserveBalance: BigNumber,
	reserveRatio: number,
	depositAmount: BigNumber,
) {
	// Handle the initialization of the bonding curve
	if (supply.eq(0)) {
		const minDeposit = await bardsStaking.minimumStaking()
		if (depositAmount.lt(minDeposit)) {
			throw new Error('deposit must be above minimum')
		}
		const defaultReserveRatio = await bardsStaking.defaultStakingReserveRatio()
		const minSupply = toBCT('1')
		return (
			(await calcBondingCurve(
				minSupply,
				minDeposit,
				defaultReserveRatio,
				depositAmount.sub(minDeposit),
			)) + toFloat(minSupply)
		)
	}
	// Calculate bonding curve in the test
	return (
		toFloat(supply) *
		((1 + toFloat(depositAmount) / toFloat(reserveBalance)) ** (reserveRatio / BPS_MAX) - 1)
	)
}

// This function calculates the Cobb-Douglas formula in Typescript so we can compare against
// the Solidity implementation
// TODO: consider using bignumber.js to get extra precision
export function cobbDouglas(
	totalRewards: number,
	fees: number,
	totalFees: number,
	stake: number,
	totalStake: number,
	alphaNumerator: number,
	alphaDenominator: number,
) {
	if (totalFees === 0) {
		return 0
	}
	const feeRatio = fees / totalFees
	const stakeRatio = stake / totalStake
	const alpha = alphaNumerator / alphaDenominator
	return totalRewards * feeRatio ** alpha * stakeRatio ** (1 - alpha)
}

export const chunkify = (total: BigNumber, maxChunks = 10): Array<BigNumber> => {
	const chunks: BigNumber[] = []
	while (total.gt(0) && maxChunks > 0) {
		const m = 1000000
		const p = Math.floor(Math.random() * m)
		const n = total.mul(p).div(m)
		chunks.push(n)
		total = total.sub(n)
		maxChunks--
	}
	if (total.gt(0)) {
		chunks.push(total)
	}
	return chunks
}

export async function stakingReturningPair(
	stakingContract: BardsStaking = bardsStaking,
	sender: Signer,
	curationId: BigNumber,
	tokens: BigNumber
): Promise<[BigNumber, BigNumber]> {
	let stakingOutPair: [BigNumber, BigNumber] = await stakingContract
		.connect(sender)
		.callStatic.stake(curationId, tokens);
	await expect(stakingContract.connect(sender).stake(curationId, tokens)).to.not.be.reverted;
	return stakingOutPair;
}

export async function unstakingReturningPair(
	stakingContract: BardsStaking = bardsStaking,
	sender: Signer,
	curationId: BigNumber,
	shares: BigNumber
): Promise<BigNumber> {
	let shareOut = await stakingContract
		.connect(sender)
		.callStatic.unstake(curationId, shares);
	await expect(stakingContract.connect(sender).unstake(curationId, shares)).to.not.be.reverted;
	return shareOut;
}