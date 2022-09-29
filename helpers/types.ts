export interface SymbolMap<T> {
	[symbol: string]: T;
}

export type eNetwork = eEthereumNetwork | ePolygonNetwork | eXDaiNetwork;

export enum eEthereumNetwork {
	goerli = 'goerli',
	sepolia = 'sepolia',
	main = 'main',
	hardhat = 'hardhat',
	tenderlyMain = 'tenderlyMain',
	harhatevm = 'harhatevm',
}

export enum ePolygonNetwork {
	matic = 'matic',
	mumbai = 'mumbai',
}

export enum eXDaiNetwork {
	xdai = 'xdai',
}

export enum EthereumNetworkNames {
	goerli = 'goerli',
	sepolia = 'sepolia',
	main = 'main',
	matic = 'matic',
	mumbai = 'mumbai',
	xdai = 'xdai',
}

export type tEthereumAddress = string;
export type tStringTokenBigUnits = string; // 1 ETH, or 10e6 USDC or 10e18 DAI
export type tStringTokenSmallUnits = string; // 1 wei, or 1 basic unit of USDC, or 1 basic unit of DAI

export type iParamsPerNetwork<T> =
	| iEthereumParamsPerNetwork<T>
	| iPolygonParamsPerNetwork<T>
	| iXDaiParamsPerNetwork<T>;

export interface iParamsPerNetworkAll<T>
	extends iEthereumParamsPerNetwork<T>,
	iPolygonParamsPerNetwork<T>,
	iXDaiParamsPerNetwork<T> { }

export interface iEthereumParamsPerNetwork<eNetwork> {
	[eEthereumNetwork.harhatevm]: eNetwork;
	[eEthereumNetwork.goerli]: eNetwork;
	[eEthereumNetwork.sepolia]: eNetwork;
	[eEthereumNetwork.main]: eNetwork;
	[eEthereumNetwork.hardhat]: eNetwork;
	[eEthereumNetwork.tenderlyMain]: eNetwork;
}

export interface iPolygonParamsPerNetwork<T> {
	[ePolygonNetwork.matic]: T;
	[ePolygonNetwork.mumbai]: T;
}

export interface iXDaiParamsPerNetwork<T> {
	[eXDaiNetwork.xdai]: T;
}

export interface ObjectString {
	[key: string]: string;
}