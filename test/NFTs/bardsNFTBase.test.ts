import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { keccak256, toUtf8Bytes } from 'ethers/lib/utils';
import { ERRORS } from '../utils/Errors';

import { 
	MAX_UINT256,
	ZERO_ADDRESS,
	BARDS_HUB_NFT_NAME,
	MOCK_PROFILE_HANDLE,
	DOMAIN_SALT
 } from "../utils/Constants";

import {
	// cancelWithPermitForAll,
	// getBurnWithSigparts,
	getChainId,
	// getPermitForAllParts,
	// getPermitParts,
} from '../utils/Helpers';

import {
	makeSuiteCleanRoom,
	abiCoder,
	bardsHub,
	testWallet,
	user,
	userAddress,
} from '../__setup.test';

makeSuiteCleanRoom('Bards NFT Base Functionality', function () {
	context('Generic Stories', function () {
		it('Domain separator fetched from contract should be accurate', async function () {
			const expectedDomainSeparator = keccak256(
				abiCoder.encode(
					['bytes32', 'bytes32', 'bytes32', 'uint256', 'address', 'bytes32'],
					[
						keccak256(
							toUtf8Bytes(
								'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)'
							)
						),
						keccak256(toUtf8Bytes(BARDS_HUB_NFT_NAME)),
						keccak256(toUtf8Bytes('1')),
						getChainId(),
						bardsHub.address,
						DOMAIN_SALT
					]
				)
			);
			// expect(
			// 	await bardsHub.getDomainSeparator()
			// ).to.eq(
			// 	expectedDomainSeparator
			// );
		});
	});
})