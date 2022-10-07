import { HardhatUserConfig } from 'hardhat/types';
import { accounts } from './cli/helpers/test-wallets';
import { eEthereumNetwork, eNetwork, ePolygonNetwork, eXDaiNetwork } from './cli/helpers/types';
import { HARDHATEVM_CHAINID } from './cli/helpers/hardhat-constants';
import { NETWORKS_RPC_URL } from './helper-hardhat-config';
import * as dotenv from 'dotenv';
import glob from 'glob';
import path from 'path';
import './bre/bre';

dotenv.config();

import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import 'solidity-coverage';
import 'hardhat-contract-sizer';
import 'hardhat-tracer';
import 'hardhat-abi-exporter';
import 'hardhat-gas-reporter';
import 'hardhat-contract-sizer';
import 'hardhat-log-remover';
import 'hardhat-spdx-license-identifier';

if (!process.env.SKIP_LOAD) {
  require('./bre/bre')
  glob.sync('./tasks/*/*.ts').forEach(function (file) {
    require(path.resolve(file));
  });
}

const DEFAULT_BLOCK_GAS_LIMIT = 12450000;
const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || '';
const MAINNET_FORK = process.env.MAINNET_FORK === 'true';
const TRACK_GAS = process.env.TRACK_GAS === 'true';
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';

const getCommonNetworkConfig = (networkName: eNetwork, chainId: number) => ({
  url: NETWORKS_RPC_URL[networkName] ?? '',
  chainId: chainId,
  accounts: {
    mnemonic: MNEMONIC,
    path: MNEMONIC_PATH,
    initialIndex: 0,
    count: 20,
  },
  bardsConfig: `configs/bards.${networkName}.yml`
});

const mainnetFork = MAINNET_FORK
  ? {
    blockNumber: 12012081,
    url: NETWORKS_RPC_URL['main'],
  }
  : undefined;

const config: HardhatUserConfig = {
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './dist/cache', 
    artifacts: './dist/contracts',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  networks: {
    goerli: getCommonNetworkConfig(eEthereumNetwork.goerli, 5),
    sepolia: getCommonNetworkConfig(eEthereumNetwork.sepolia, 11155111),
    main: getCommonNetworkConfig(eEthereumNetwork.main, 1),
    tenderlyMain: getCommonNetworkConfig(eEthereumNetwork.tenderlyMain, 3030),
    matic: getCommonNetworkConfig(ePolygonNetwork.matic, 137),
    mumbai: getCommonNetworkConfig(ePolygonNetwork.mumbai, 80001),
    xdai: getCommonNetworkConfig(eXDaiNetwork.xdai, 100),
    hardhat: {
      hardfork: 'london',
      blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
      gas: DEFAULT_BLOCK_GAS_LIMIT,
      gasPrice: 8000000000,
      chainId: HARDHATEVM_CHAINID,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      accounts: accounts.map(({ secretKey, balance }: { secretKey: string; balance: string }) => ({
        privateKey: secretKey,
        balance,
      })),
      forking: mainnetFork,
      allowUnlimitedContractSize: false,
    },
  },
  bards: {
    addressBook: process.env.ADDRESS_BOOK ?? 'addresses.json',
    l1BardsConfig: process.env.BARDS_CONFIG ?? 'configs/bards.localhost.yml',
    l2BardsConfig: process.env.L2_BARDS_CONFIG,
  },
  gasReporter: {
    enabled: TRACK_GAS ? true : false,
    showTimeSpent: true,
    currency: 'USD',
    outputFile: './dist/reports/gas-report.log',
  },
  abiExporter: {
    path: './dist/abis',
    clear: true,
    flat: true,
    runOnCompile: true,
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  typechain: {
    outDir: 'dist/types',
    target: 'ethers-v5',
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: false,
  },
};

export default config;
