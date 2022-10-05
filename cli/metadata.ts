enum ProtocolState {
	Unpaused,
	CurationPaused,
	Paused,
}

interface AccountMetadata {
	codeRepository: string
	description: string
	image: string
	name: string
	website: string
	displayName
}

interface CurationMetadata {
	description: string
	displayName: string
	image: string
	codeRepository: string
	website: string
}

interface VersionMetadata {
	label: string
	description: string
}

const jsonToCurationMetadata = (json): CurationMetadata => {
	const subgraphMetadata: CurationMetadata = {
		description: checkString(json.description),
		displayName: checkString(json.displayName),
		image: checkString(json.image),
		codeRepository: checkString(json.codeRepository),
		website: checkString(json.website),
	}
	return subgraphMetadata
}

const jsonToVersionMetadata = (json): VersionMetadata => {
	const subgraphMetadata: VersionMetadata = {
		label: checkString(json.label),
		description: checkString(json.description),
	}
	return subgraphMetadata
}

const jsonToAccountMetadata = (json): AccountMetadata => {
	const accountMetadata: AccountMetadata = {
		codeRepository: checkString(json.codeRepository),
		description: checkString(json.description),
		image: checkString(json.image),
		name: checkString(json.name),
		website: checkString(json.website),
		displayName: checkString(json.displayName),
	}
	return accountMetadata
}

const checkString = (field): string => {
	if (typeof field != 'string') {
		throw Error('Metadata field is incorrect for one or more files')
	}
	return field
}

export {
	ProtocolState,
	AccountMetadata,
	CurationMetadata,
	VersionMetadata,
	jsonToCurationMetadata,
	jsonToVersionMetadata,
	jsonToAccountMetadata,
}