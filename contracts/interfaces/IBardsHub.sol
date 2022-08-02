// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from '../utils/DataTypes.sol';

/**
 * @title IBardsHub
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the TheBards contract, the main entry point for the TheBards Protocol.
 */
interface IBardsHub {

	// -- Governance --

	/**
     * @notice Initializes the TheBards NFT, setting the initial governance address as well as the name and symbol in
     * the BardsNFTBase contract.
     *
     * @param name The name to set for the hub NFT.
     * @param symbol The symbol to set for the hub NFT.
     * @param newGovernance The governance address to set.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance
    ) external;

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) 
		external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) 
		external;

	/**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(DataTypes.ProtocolState newState) 
		external;

	/**
     * @notice Adds or removes a market module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param marketModule The market module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the market module should be whitelisted.
     */
    function whitelistMarketModule(address marketModule, bool whitelist) 
		external;

	/**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) 
		external;

	// -- Registry --

	// -- Pausing --

	// -- Epoch Manage --

	// -- Reward Manage --

	// -- cruation funtions --
	/**
     * @notice Creates a profile with the specified parameters, minting a self curation as NFT to the given recipient.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the profile's token ID.
     */
    function createProfile(DataTypes.CreateCurationData calldata vars) 
		external 
		returns (uint256);

    /**
     * @notice Creates a profile with the specified parameterse via signature with the specified parameters.
     *
     * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the profile's token ID.
     */
    function createProfileWithSig(DataTypes.CreateCurationWithSigData calldata vars) external returns (uint256);

    /**
     * @notice Sets the mapping between wallet and its main profile identity.
     *
     * @param profileId The token ID of the profile to set as the main profile identity.
     */
    function setDefaultProfile(uint256 profileId) 
		external;

    /**
     * @notice Sets the mapping between wallet and its main profile identity via signature with the specified parameters.
     *
     * @param vars A SetDefaultProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

	    /**
     * @notice Sets a curation's market module, must be called by the curator.
     *
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the market module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The market module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the market module for initialization.
     */
    function setMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's market module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

	    /**
     * @notice Sets a curation's mint module, must be called by the curator.
     *
     * @param vars The SetMintModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the mint module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The mint module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the mint module for initialization.
     */
    function setMintModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's mint module via signature with the specified parameters.
     *
     * @param vars A SetMintModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMintModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

    /**
     * @notice Creates a curation to a given profile, must be called by the profile owner.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCuration(DataTypes.CreateCurationData calldata vars) external returns (uint256);

    /**
     * @notice Creates a curation to a given profile via signature with the specified parameters.
     *
     * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCurationWithSig(DataTypes.CreateCurationWithSigData calldata vars) external returns (uint256);

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns default profile for a given wallet address
     *
     * @param wallet The address to find the default mapping
     *
     * @return uint256 The default profile id, which will be 0 if not mapped.
     */
    function defaultProfile(address wallet) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns whether or not a market module is whitelisted.
     *
     * @param marketModule The address of the market module to check.
     *
     * @return bool True if the the market module is whitelisted, false otherwise.
     */
    function isMarketModuleWhitelisted(address marketModule) 
		external 
		view 
		returns (bool);

	/**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the collect module associated with the queried curation.
     */
    function getMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the handle associated with a profile.
     *
     * @param profileId The token ID of the profile to query the handle for.
     *
     * @return string The handle associated with the profile.
     */
    function getHandle(uint256 profileId) 
		external 
		view 
		returns (string memory);

	    /**
     * @notice Returns the URI associated with a given curation.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(uint256 curationId) 
		external 
		view 
		returns (string memory);

    /**
     * @notice Returns the profile token ID according to a given handle.
     *
     * @param handle The handle to resolve the profile token ID with.
     *
     * @return uint256 The profile ID the passed handle points to.
     */
    function getProfileIdByHandle(string calldata handle) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return ProfileStruct The profile struct of the given profile.
     */
    function getProfile(uint256 profileId) 
		external 
		view 
		returns (DataTypes.CurationStruct memory);

    /**
     * @notice Returns the full curationId struct.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return CurationStruct The curation struct associated with the queried curation.
     */
    function getCuration(uint256 curationId)
        external
        view
        returns (DataTypes.CurationStruct memory);

}