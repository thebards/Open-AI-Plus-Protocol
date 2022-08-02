// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './DataTypes.sol';
import './Errors.sol';
import './Events.sol';
import './Constants.sol';
import '../interfaces/markets/IMarketModule.sol';

/**
 * @title CurationHelpers
 * @author TheBards Protocol
 *
 * @notice This is the library that contains the logic for profile creation, publication, and Interaction.
 *
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood. Furthermore,
 * expected events are emitted from this library instead of from the hub to alleviate code size concerns.
 */
library CurationHelpers {
	using CurationHelpers for DataTypes.CurationStruct;
	using CurationHelpers for DataTypes.CreateCurationData;

	/**
     * @notice Executes the logic to create a profile with the given parameters to the given address.
     *
     * @param vars The CreateProfileData struct.
     * @param profileId The profile ID to associate with this profile NFT (token ID).
     * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
     * @param _curationById The storage reference to the mapping of profile structs by IDs.
	 * @param _isProfileById The storage reference to whether the Id is belong to profile.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     */
    function createProfile(
        DataTypes.CreateCurationData calldata vars,
        uint256 profileId,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
		mapping(uint256 => bool) storage _isProfileById,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        _validateHandle(vars.handle);
        bytes32 handleHash = keccak256(bytes(vars.handle));
        if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleTaken();

        _profileIdByHandleHash[handleHash] = profileId;

        _curationById[profileId].handle = vars.handle;
        _curationById[profileId].contentURI = vars.contentURI;
		_isProfileById[profileId] = true;

        bytes memory marketModuleReturnData;
        if (vars.marketModule != address(0)) {
            _curationById[profileId].marketModule = vars.marketModule;
            marketModuleReturnData = _initMarketModule(
				msg.sender, // Creator is always the profile's owner
                profileId,
                vars.marketModule,
                vars.marketModuleInitData,
                _marketModuleWhitelisted
            );
        }
		bytes memory mintModuleReturnData;
        if (vars.mintModule != address(0)) {
            _curationById[profileId].mintModule = vars.mintModule;
			mintModuleReturnData = _initMarketModule(
				msg.sender, // Creator is always the profile's owner
                profileId,
				vars.mintModule,
				vars.mintModuleInitData,
                _marketModuleWhitelisted
            );
        }

        _emitProfileCreated(profileId, vars, marketModuleReturnData, mintModuleReturnData);
    }

    /**
     * @notice Sets the market module for a given curation.
     *
     * @param curationId The curation token ID to set the market module for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The market module to set for the given curation, if any.
     * @param marketModuleInitData The data to pass to the market module for curation initialization.
     * @param _curation The storage reference to the curation struct associated with the given curation token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     */
    function setMarketModule(
		uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        DataTypes.CurationStruct storage _curation,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        if (marketModule != _curation.marketModule) {
            _curation.marketModule = marketModule;
        }

        bytes memory marketModuleReturnData;
        if (marketModule != address(0))
            marketModuleReturnData = _initMarketModule(
				tokenContract,
                tokenId,
                marketModule,
                marketModuleInitData,
                _marketModuleWhitelisted
            );

        emit Events.MarketModuleSet(
			curationId,
            marketModule,
            marketModuleInitData,
            block.timestamp
        );
    }

	/**
     * @notice Sets the mint module for a given curation.
     *
     * @param curationId The curation token ID to set the market module for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The market module to set for the given curation, if any.
     * @param marketModuleInitData The data to pass to the market module for curation initialization.
     * @param _curation The storage reference to the curation struct associated with the given curation token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     */
    function setMintModule(
		uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        DataTypes.CurationStruct storage _curation,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        if (marketModule != _curation.mintModule) {
            _curation.mintModule = marketModule;
        }

        bytes memory marketModuleReturnData;
        if (marketModule != address(0))
            marketModuleReturnData = _initMarketModule(
				tokenContract,
                tokenId,
                marketModule,
                marketModuleInitData,
                _marketModuleWhitelisted
            );
			 
        emit Events.MintModuleSet(
			curationId,
            marketModule,
            marketModuleInitData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a curation mapped to the given profile.
     *
     * @dev To avoid a stack too deep error, reference parameters are passed in memory rather than calldata.
     *
     * @param profileId The profile ID to associate this curation to.
	 * @param curationId The token ID to associate with this curation.
       @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param contentURI The URI to set for this curation.
     * @param marketModule The market module to set for this publication.
     * @param marketModuleInitData The data to pass to the market module for curation initialization.
     * @param mintModule The mint module to set for this curation, if any.
     * @param mintModuleInitData The data to pass to the mint module for curation initialization.
     * @param _curationById The storage reference to the mapping of curations by token ID.
     * @param _isMintedByIdById The storage reference to the mapping of ownership by token Id by profile Id.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
     */
    function createCuration(
        uint256 profileId,
		uint256 curationId,
        address tokenContractPointed,
        uint256 tokenIdPointed,
        string memory contentURI,
        address marketModule,
        bytes memory marketModuleInitData,
        address mintModule,
        bytes memory mintModuleInitData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
		mapping(uint256 => mapping(uint256 => bool)) storage _isMintedByIdById,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        _curationById[curationId].contentURI = contentURI;
		_curationById[curationId].tokenContractPointed = tokenContractPointed;
		_curationById[curationId].tokenIdPointed = tokenIdPointed;
		_isMintedByIdById[profileId][curationId] = true;

        bytes memory marketModuleReturnData;
        if (marketModule != address(0)) {
            _curationById[profileId].marketModule = marketModule;
            marketModuleReturnData = _initMarketModule(
				msg.sender, // Creator is always the profile's owner
                curationId,
                marketModule,
                marketModuleInitData,
                _marketModuleWhitelisted
            );
        }
		bytes memory mintModuleReturnData;
        if (mintModule != address(0)) {
            _curationById[profileId].mintModule = mintModule;
			mintModuleReturnData = _initMarketModule(
				msg.sender, // Creator is always the profile's owner
                curationId,
				mintModule,
				mintModuleInitData,
                _marketModuleWhitelisted
            );
        }

        emit Events.CurationCreated(
            profileId,
            curationId, 
            contentURI,
            marketModule,
            marketModuleInitData,
            mintModule,
            mintModuleInitData,
            block.timestamp
        );
    }

	function _initMarketModule(
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) private returns (bytes memory) {
        if (!_marketModuleWhitelisted[marketModule]) revert Errors.MarketModuleNotWhitelisted();
        return IMarketModule(marketModule).initializeModule(tokenContract, tokenId, marketModuleInitData);
    }

    function _emitProfileCreated(
        uint256 profileId,
        DataTypes.CreateCurationData calldata vars,
        bytes memory marketModuleReturnData,
		bytes memory mintModuleReturnData
    ) internal {
        emit Events.ProfileCreated(
            profileId,
            msg.sender, // Creator is always the msg sender
            vars.to,
            vars.handle,
            vars.contentURI,
            vars.marketModule,
            marketModuleReturnData,
            vars.mintModule,
            mintModuleReturnData,
            block.timestamp
        );
    }

	function _validateHandle(string calldata handle) private pure {
        bytes memory byteHandle = bytes(handle);
        if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH)
            revert Errors.HandleLengthInvalid();

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < '0' ||
                    byteHandle[i] > 'z' ||
                    (byteHandle[i] > '9' && byteHandle[i] < 'a')) &&
                byteHandle[i] != '.' &&
                byteHandle[i] != '-' &&
                byteHandle[i] != '_'
            ) revert Errors.HandleContainsInvalidCharacters();
            unchecked {
                ++i;
            }
        }
    }
}