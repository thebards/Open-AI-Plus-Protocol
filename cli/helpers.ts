import fs from 'fs'
import * as dotenv from 'dotenv'

import { utils, providers, Wallet } from 'ethers'
import ipfsHttpClient from 'ipfs-http-client'
import inquirer from 'inquirer'

import * as bs58 from 'bs58'

import { logger } from './logging'

import {
	CurationMetadata,
	VersionMetadata,
	jsonToCurationMetadata,
	jsonToVersionMetadata,
} from './metadata'

dotenv.config()

export class IPFS {
	static createIpfsClient(node: string): typeof ipfsHttpClient {
		let url: URL
		try {
			url = new URL(node)
		} catch (e) {
			throw new Error(
				`Invalid IPFS URL: ${node}. ` +
				`The URL must be of the following format: http(s)://host[:port]/[path]`,
			)
		}

		return ipfsHttpClient({
			protocol: url.protocol.replace(/[:]+$/, ''),
			host: url.hostname,
			'api-path': url.pathname.replace(/\/$/, '') + '/api/v0/',
		})
	}

	static ipfsHashToBytes32(hash: string): string {
		const hashBytes = bs58.decode(hash).slice(2)
		return utils.hexlify(hashBytes)
	}
}

export const pinMetadataToIPFS = async (
	ipfs: string,
	type: string,
	path?: string, // Only pass path or metadata, not both
	metadata?: CurationMetadata | VersionMetadata,
): Promise<string> => {
	if (metadata == undefined && path != undefined) {
		if (type == 'subgraph') {
			metadata = jsonToCurationMetadata(JSON.parse(fs.readFileSync(__dirname + path).toString()))
			logger.info('Meta data:')
			logger.info(`  Curation Description:     ${metadata.description}`)
			logger.info(`Curation Display Name:    ${metadata.displayName}`)
			logger.info(`  Curation Image:           ${metadata.image}`)
			logger.info(`  Curation Code Repository: ${metadata.codeRepository}`)
			logger.info(`  Curation Website:         ${metadata.website}`)
		} else if (type == 'version') {
			metadata = jsonToVersionMetadata(JSON.parse(fs.readFileSync(__dirname + path).toString()))
			logger.info('Meta data:')
			logger.info(`  Version Description:      ${metadata.description}`)
			logger.info(`  Version Label:            ${metadata.label}`)
		}
	}

	const ipfsClient = new ipfsHttpClient(ipfs + 'api/v0')
	let result
	logger.info(`\nUpload JSON meta data for ${type} to IPFS...`)
	try {
		result = await ipfsClient.add(Buffer.from(JSON.stringify(metadata)))
	} catch (e) {
		logger.error(`Failed to upload to IPFS: ${e}`)
		return ''
	}

	const metaHash = result.path

	// TODO - maybe add this back in. ipfs-http-client was updated, so it broke
	// try {
	//   const data = await ipfsClient.cat(metaHash)
	//   if (JSON.stringify(data) !== JSON.stringify(metadata)) {
	//     throw new Error(`Original meta data and uploaded data are not identical`)
	//   }
	// } catch (e) {
	//   throw new Error(`Failed to retrieve and parse JSON meta data after uploading: ${e.message}`)
	// }
	logger.info(`Upload metadata successful: ${metaHash}\n`)
	return IPFS.ipfsHashToBytes32(metaHash)
}

export const confirm = async (message: string, skip: boolean): Promise<boolean> => {
	if (skip) return true
	const res = await inquirer.prompt({
		name: 'confirm',
		type: 'confirm',
		message,
	})
	if (!res.confirm) {
		logger.info('Cancelled')
		return false
	}
	return true
}