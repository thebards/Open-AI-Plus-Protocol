import { AbiCoder } from '@ethersproject/abi';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect, use } from 'chai';
import { BytesLike, Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';

import {
	revertToSnapshot,
	takeSnapshot,
} from './utils/helpers';


export function makeSuiteCleanRoom(name: string, tests: () => void) {
	describe(name, () => {
		beforeEach(async function () {
			await takeSnapshot();
		});
		tests();
		afterEach(async function () {
			await revertToSnapshot();
		});
	});
}