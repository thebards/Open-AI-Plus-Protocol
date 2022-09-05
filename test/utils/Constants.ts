import { parseEther } from '@ethersproject/units';
import {toBCT, toBN} from './Helpers';

export const MAX_UINT256 = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
export const WETH_ADDRESS = '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720';
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const FAKE_PRIVATEKEY = '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6';
export const HARDHAT_CHAINID = 31337;
export const DOMAIN_SALT = '0x51f3d585afe6dfeb2af01bba0889a36c1db03beec88c6a4d0c53817069026afa';

export const FIRST_PROFILE_ID = 1;
export const CURRENCY_MINT_AMOUNT = parseEther('100');
export const BPS_MAX = 1000000;
export const PROTOCOL_FEE = 5000;
export const DEFAULT_CURATION_BPS = 100000;
export const DEFAULT_STAKING_BPS = 100000;
export const BARDS_HUB_NFT_NAME = 'TheBards HUB';
export const BARDS_HUB_NFT_SYMBOL = 'TBH';
export const MOCK_PROFILE_HANDLE = 'thebards.bpp';
export const MOCK_PROFILE_CONTENT_URI = '';

export const DEFAULTS = {
	epochs: {
		lengthInBlocks: toBN((15 * 60) / 15), // 15 minutes in blocks
	},
	staking: {
		minimumStake: toBCT('10'),
		reserveRatio: toBN('500000'),
		stakingTaxPercentage: 0,
		channelDisputeEpochs: 1,
		maxAllocationEpochs: 5,
		thawingPeriod: 20, // in blocks
		delegationUnbondingPeriod: 1, // in epochs
		alphaNumerator: 85,
		alphaDenominator: 100,
	},
	token: {
		initialSupply: toBCT('10000000000'), // 10 billion
	},
	rewards: {
		issuanceRate: toBCT('1.000000023206889619'), // 5% annual rate
	},
}