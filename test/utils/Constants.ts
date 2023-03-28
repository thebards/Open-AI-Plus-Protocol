import { parseEther } from '@ethersproject/units';
import {toBCT, toBN} from './Helpers';

export const MAX_UINT256 = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
export const WETH_ADDRESS = '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720';
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const FAKE_PRIVATEKEY = '0xa2e0097c961c67ec197b6865d7ecea6caffc68ebeb00e6050368c8f67fc9c588';
export const HARDHAT_CHAINID = 31337;
export const DOMAIN_SALT = '0x51f3d585afe6dfeb2af01bba0889a36c1db03beec88c6a4d0c53817069026afa';

export const FIRST_PROFILE_ID = 1;
export const CURRENCY_MINT_AMOUNT = parseEther('100');
export const BPS_MAX = 1000000;  // 100%
export const PROTOCOL_FEE = 5000; // 0.5%
export const DEFAULT_CURATION_BPS = 100000; // 10%
export const DEFAULT_STAKING_BPS = 100000;  // 10%
export const BARDS_HUB_NFT_NAME = 'TheBards HUB';
export const BARDS_HUB_NFT_SYMBOL = 'TBH';
export const BARDS_CURATION_TOKEN_NAME = 'Bards Curation Token';
export const BARDS_CURATION_TOKEN_SYMBOL = 'BCT';
export const MOCK_PROFILE_HANDLE = 'thebards.bpp';
export const MOCK_PROFILE_HANDLE2 = 'thebards2.bpp';
export const MOCK_PROFILE_CONTENT_URI = 'https://thebards.xyz';
export const ISSUANCE_RATE_PERIODS = 4 // blocks required to issue 5% rewards
export const ISSUANCE_RATE_PER_BLOCK = toBN('1012272234429039270') // % increase every block

export const DEFAULTS = {
	epochs: {
		lengthInBlocks: toBN((15 * 60) / 15), // 15 minutes in blocks
	},
	staking: {
		minimumStake: toBCT('10'),
		reserveRatio: toBN('500000'),
		stakingTaxPercentage: toBN('0'),
		claimThawingPeriod: 1,
		maxAllocationEpochs: 5,
		thawingPeriod: 1, // in epochs
		alphaNumerator: 85,
		alphaDenominator: 100,
	},
	token: {
		initialSupply: toBCT('10000000000'), // 10 billion
	},
	rewards: {
		issuanceRate: toBCT('1.000000023206889619'), // 5% annual rate
		inflationChange: 3,
		targetBondingRate: 500000
	},
}