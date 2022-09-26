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
     * @param cooldownBlocks Number of blocks to set the curation parameters cooldown period
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance,
        uint32 cooldownBlocks
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
     * @notice Set the time in blocks an curator needs to wait to change curation parameters.
     * @param _blocks Number of blocks to set the curation parameters cooldown period
     */
    function setCooldownBlocks(uint32 _blocks) 
		  external;

	/**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     *   ########################################################
     *   ##                 Unpaused | Paused | CurationPaused ##
     *   ## governance     |   yes   |   yes  |      yes       ##
     *   ## emergency admin|   no    |   yes  |      yes       ##
     *   ## other          |   no    |   no   |      no        ##
     *   ########################################################
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(DataTypes.ProtocolState newState) 
		external;

    /**
    * @notice Updates a curation with the specified parameters. 
    */
	  function updateCuration(DataTypes.InitializeCurationData memory _vars) external;

    /**
     * @notice Sets the sellerFundsRecipients of the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerFundsRecipients The bpses of seller funds
     */
    function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) external;

    /**
     * @notice Sets the curationFundsRecipients of the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationFundsRecipients The bpses of curation funds
     */
    function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) external;


    /**
     * @notice Sets the fee that is sent to the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerFundsBpses The fee that is sent to the sellers.
     */
    function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) external;

    /**
     * @notice Sets the fee that is sent to the curation for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationFundsBpses The fee that is sent to the curations.
     */
    function setCurationFundsBpsesParams(uint256 tokenId, uint32[] calldata curationFundsBpses) external;

	/**
     * @notice Sets fee parameters for a NFT
	 *
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     * @param stakingBps The bps of staking
     */
    function setBpsParams(uint256 tokenId, uint32 curationBps, uint32 stakingBps) external;

    /**
     * @notice Sets curation fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     */
    function setCurationBpsParams(uint256 tokenId, uint32 curationBps) external;

    /**
     * @notice Sets staking fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param stakingBps The bps of staking
     */
    function setStakingBpsParams(uint256 tokenId, uint32 stakingBps) external;

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
     * @notice Adds or removes a mint module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param minterModule The mint module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the mint module should be whitelisted.
     */
    function whitelistMinterModule(address minterModule, bool whitelist) 
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

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function registerContract(bytes32 _id, address _contractAddress) external;

    /**
     * @notice Unregister a contract address
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function unsetContract(bytes32 _id) external;

    /**
     * @notice Get contract registered address by its id
     * @param _id Contract id
     */
    function getContractAddressRegistered(bytes32 _id) external view returns (address);

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

    // /**
    //  * @notice Creates a profile with the specified parameterse via signature with the specified parameters.
    //  *
    //  * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
    //  *
    //  * @return uint256 An integer representing the profile's token ID.
    //  */
    // function createProfileWithSig(DataTypes.CreateCurationWithSigData calldata vars) 
    // external 
    // returns (uint256);

    /**
     * @notice Sets the mapping between wallet and its main profile identity.
     *
     * @param profileId The token ID of the profile to set as the main profile identity.
     */
    function setDefaultProfile(uint256 profileId) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID.
     *
     * @param vars A SetAllocationIdData struct, including the regular parameters
     */
    function setAllocationId(DataTypes.SetAllocationIdData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID via signature with the specified parameters.
     *
     * @param vars A SetAllocationIdWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setAllocationIdWithSig(DataTypes.SetAllocationIdWithSigData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between wallet and its main profile identity via signature with the specified parameters.
     *
     * @param vars A SetDefaultProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

    /**
     * @notice Sets a curation's content URI.
     *
     * @param curationId The token ID of the curation to set the URI for.
     * @param contentURI The URI to set for the given curation.
     */
    function setCurationContentURI(uint256 curationId, string calldata contentURI) external;

    /**
     * @notice Sets a curation's content URI via signature with the specified parameters.
     *
     * @param vars A SetCurationContentURIWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setCurationContentURIWithSig(DataTypes.SetCurationContentURIWithSigData calldata vars)
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
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the mint module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The mint module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the mint module for initialization.
     */
    function setMinterMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's mint module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMinterMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
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
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /**
     * @notice Creates a curation via signature with the specified parameters.
     *
     * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCurationWithSig(
      DataTypes.CreateCurationWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Collects a given curation, executing market module logic and transfering curation to the caller.
     *
     * @param vars A SimpleDoCollectData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collect(
      DataTypes.SimpleDoCollectData calldata vars
    ) external returns (address, uint256);

    /**
     * @notice Collects a given curation via signature with the specified parameters.
     *
     * @param vars A CollectWithSigData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collectWithSig(
      DataTypes.DoCollectWithSigData calldata vars
    ) external returns (address, uint256);

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether `spender` is allowed to manage things for `curator`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * 
     * @param operator The address of operator
     * @param curator The address of curation.
     */
    function isAuthForCurator(address operator, address curator)
      external
      view
      returns (bool);

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
     * @notice Returns whether or not a mint module is whitelisted.
     *
     * @param minterModule The address of the mint module to check.
     *
     * @return bool True if the the mint module is whitelisted, false otherwise.
     */
    function isMinterModuleWhitelisted(address minterModule) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool);

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
     * @return address The address of the market module associated with the queried curation.
     */
    function getMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the minter market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the mint module associated with the queried curation.
     */
    function getMinterMarketModule(uint256 curationId) 
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

    /**
     * @notice Returns the allocation Id.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return allocationId The allocation ID associated with the queried curation.
     */
    function getAllocationIdById(uint256 curationId)
        external
        view
        returns (uint256);

    /**
     * @notice remove allocations in _isToBeClaimedByAllocByCurator.
     */
    function removeAllocation(
        address curator, 
        uint256 allocationId
    ) external;

}