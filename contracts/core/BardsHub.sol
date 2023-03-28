// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {BardsCurationBase} from './curations/BardsCurationBase.sol';
import {BardsHubStorage} from './storages/BardsHubStorage.sol';
import {IBardsHub} from '../interfaces/IBardsHub.sol';
import {DataTypes} from '../utils/DataTypes.sol';
import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';
import {VersionedInitializable} from '../upgradeablity/VersionedInitializable.sol';
import {CurationHelpers} from '../utils/CurationHelpers.sol';
import {CodeUtils} from '../utils/CodeUtils.sol';
import {Errors} from '../utils/Errors.sol';
import {Events} from '../utils/Events.sol';
import {Constants} from '../utils/Constants.sol';
import {BardsPausable} from './govs/BardsPausable.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title BardsHub
 * @author TheBards Protocol
 *
 * @notice This is the main entrypoint of the Bards Protocol.
 */
contract BardsHub is
    BardsCurationBase,
    VersionedInitializable,
    BardsPausable,
    BardsHubStorage,
    IBardsHub
{
    using CurationHelpers for DataTypes.CreateCurationData;
    using CurationHelpers for DataTypes.UpdateCurationDataParamsData;
    using CodeUtils for DataTypes.SetCurationContentURIWithSigData;
    using CodeUtils for DataTypes.SetAllocationIdWithSigData;
    using CodeUtils for DataTypes.SetMarketModuleWithSigData;
    using CodeUtils for DataTypes.CreateCurationWithSigData;
    using CodeUtils for DataTypes.DoCollectWithSigData;
    using CodeUtils for DataTypes.SetDefaultProfileWithSigData;

    uint256 internal constant REVISION = 1;
    
    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /// @inheritdoc IBardsHub
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance,
        uint32 cooldownBlocks
    ) 
        external 
        override 
        initializer
    {
        BardsCurationBase._initialize(name, symbol, cooldownBlocks);
        _setState(DataTypes.ProtocolState.Paused);
        _setGovernance(newGovernance);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /// @inheritdoc IBardsHub
    function setGovernance(address newGovernance) 
        external 
        override 
        onlyGov {
            _setGovernance(newGovernance);
    }

    /// @inheritdoc IBardsHub
    function setEmergencyAdmin(address newEmergencyAdmin)
        external
        override
        onlyGov{
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setState(DataTypes.ProtocolState newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused)
                revert Errors.EmergencyAdminCannotUnpause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    /// @inheritdoc IBardsHub
    function setCooldownBlocks(
        uint32 _blocks
    ) 
        external 
        override 
        onlyGov 
    {

        _setCooldownBlocks(_blocks);
    }

    ///@inheritdoc IBardsHub
    function whitelistProfileCreator(address profileCreator, bool whitelist)
        external
        override
        onlyGov
    {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(
            profileCreator,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistMarketModule(address marketModule, bool whitelist)
        external
        override
        onlyGov
    {
        _marketModuleWhitelisted[marketModule] = whitelist;
        emit Events.MarketModuleWhitelisted(
            marketModule,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistMinterModule(address minterModule, bool whitelist)
        external
        override
        onlyGov
    {
        _minterModuleWhitelisted[minterModule] = whitelist;
        emit Events.MinterModuleWhitelisted(
            minterModule,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function registerContract(
        bytes32 _id, 
        address _contractAddress
    )
        external
        override
        onlyGov
    {
        require(_contractAddress != address(0), "Contract address must be set");
        _registry[_id] = _contractAddress;
        _isRegisteredAddress[_contractAddress] = true;
        emit Events.ContractRegistered(
            _id, 
            _contractAddress, 
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function unsetContract(bytes32 _id) 
        external 
        override 
        onlyGov 
    {
        _registry[_id] = address(0);
        emit Events.ContractRegistered(_id, address(0), block.timestamp);
    }

    /// @inheritdoc IBardsHub
    function getContractAddressRegistered(bytes32 _id) 
        public 
        view 
        override 
        returns (address) 
    {
        return _registry[_id];
    }

    /// *********************************
    /// *****PROFILE OWNER FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IBardsHub
    function createProfile(DataTypes.CreateCurationData memory vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        if (!_profileCreatorWhitelisted[msg.sender])
            revert Errors.ProfileCreatorNotWhitelisted();

        unchecked {
            uint256 profileId = ++_curationCounter;
            uint256 allocationId = ++_allocationCounter;
            _mint(vars.to, profileId);
            vars.profileId = profileId;
            vars.tokenContractPointed = address(this);
            vars.tokenIdPointed = profileId;
            
            vars.createProfile(
                allocationId,
                _cooldownBlocks,
                _getBardsStaking(),
                _curationData,
                _profileIdByHandleHash,
                _curationById,
                _marketModuleWhitelisted,
                _isToBeClaimedByAllocByCurator
            );

            return profileId;
        }
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfile(uint256 profileId)
        external
        override
        whenNotPaused
    {
        _setDefaultProfile(msg.sender, profileId);
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfileWithSig(
        DataTypes.SetDefaultProfileWithSigData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
    {
        unchecked {
            _validateRecoveredAddress(
                vars.encodeDefaultProfileWithSigMessage(
                    sigNonces[vars.wallet]++
                ),
                name(),
                vars.wallet,
                vars.sig
            );
            _setDefaultProfile(vars.wallet, vars.profileId);
        }
    }

    /// @inheritdoc IBardsHub
    function setCurationContentURI(
        uint256 curationId, 
        string calldata contentURI
    )
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(curationId);
        _setCurationContentURI(curationId, contentURI);
    }

    /// @inheritdoc IBardsHub
    function setCurationContentURIWithSig(
        DataTypes.SetCurationContentURIWithSigData calldata vars
    )
        external
        override
        whenNotPaused 
    {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeCurationContentURIWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        _setCurationContentURI(vars.curationId, vars.contentURI);
    }

    /// @inheritdoc IBardsHub
    function setAllocationId(
        DataTypes.SetAllocationIdData calldata vars
    )
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        if (vars.allocationId == 0)
            revert Errors.ZeroAllocationId();
        if (_existsAllocationId(vars.allocationId))
            revert Errors.AllocationExists();

        address owner = ownerOf(vars.curationId);
        // reset allocation
        _getBardsStaking().closeAndAllocate(
            _curationById[vars.curationId].allocationId,
            vars.stakeToCuration,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.curationId,
                recipientsMeta: vars.curationMetaData,
                allocationId: vars.allocationId
            })
        );
        _curationById[vars.curationId].allocationId = vars.allocationId;
        _isToBeClaimedByAllocByCurator[owner][vars.allocationId] = true;
        
        emit Events.AllocationIdSet(
            vars.curationId,
            vars.allocationId,
            vars.curationMetaData,
            vars.stakeToCuration,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setAllocationIdWithSig(
        DataTypes.SetAllocationIdWithSigData calldata vars
    )
        external
        override
        whenNotPaused
    {
        if (vars.allocationId == 0)
            revert Errors.ZeroAllocationId();
        if (_existsAllocationId(vars.allocationId))
            revert Errors.AllocationExists();
        address owner = ownerOf(vars.curationId);

        unchecked {
            _validateRecoveredAddress(
                vars.encodeAllocationIdWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }

        // init allocation
        _getBardsStaking().closeAndAllocate(
            _curationById[vars.curationId].allocationId,
            vars.stakeToCuration,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.curationId,
                recipientsMeta: vars.curationMetaData,
                allocationId: vars.allocationId
            })
        );
        _curationById[vars.curationId].allocationId = vars.allocationId;
        _isToBeClaimedByAllocByCurator[owner][vars.allocationId] = true;

        emit Events.AllocationIdSet(
            vars.curationId,
            vars.allocationId,
            vars.curationMetaData,
            vars.stakeToCuration,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setMarketModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        CurationHelpers.setMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMarketModuleWithSig(
        DataTypes.SetMarketModuleWithSigData calldata vars
    ) external override whenNotPaused {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeMarketModuleWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        CurationHelpers.setMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMinterMarketModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        CurationHelpers.setMinterMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMinterMarketModuleWithSig(
        DataTypes.SetMarketModuleWithSigData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
    {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeMarketModuleWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        CurationHelpers.setMinterMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function createCuration(DataTypes.CreateCurationData calldata vars)
        external
        override
        whenCurationEnabled
        returns (uint256)
    {
        _validateCallerIsCurationOwnerOrApproved(vars.profileId);
        return _createCuration(vars);
    }

    /// @inheritdoc IBardsHub
    function createCurationWithSig(
        DataTypes.CreateCurationWithSigData calldata vars
    )
        external
        override
        whenCurationEnabled
        returns (uint256)
    { 
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeCreateCurationWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        return _createCuration(
            DataTypes.CreateCurationData({
                to: owner,
                curationType: vars.curationType,
                profileId: vars.profileId,
                curationId: vars.curationId,
                tokenContractPointed: vars.tokenContractPointed,
                tokenIdPointed: vars.tokenIdPointed,
                handle: vars.handle,
                contentURI: vars.contentURI,
                marketModule: vars.marketModule,
                marketModuleInitData: vars.marketModuleInitData,
                minterMarketModule: vars.minterMarketModule,
                minterMarketModuleInitData: vars.minterMarketModuleInitData,
                curationMetaData: vars.curationMetaData,
                curationFrom: vars.curationFrom
            }
        ));
    }

    /// @inheritdoc IBardsHub
	function updateCuration(
        DataTypes.InitializeCurationData memory _vars
    )
		external
		override
	{

        _validateCallerIsCurationOwnerOrApproved(_vars.tokenId);
        
        // reset allocation for curation
        address owner = ownerOf(_vars.tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
		CurationHelpers.setCurationRecipientsParams(
            _vars, 
            owner,
            newAllocationId,
            _cooldownBlocks, 
            _getBardsStaking(),
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );
	}

    // /// @inheritdoc IBardsHub
	// function setSellerFundsRecipientsParams(
	// 	uint256 tokenId, 
	// 	address[] calldata sellerFundsRecipients
	// ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setSellerFundsRecipientsParams(
    //         sellerFundsRecipients, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) 
	// 	external 
	// 	virtual 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);
    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setCurationFundsRecipientsParams(
    //         curationFundsRecipients, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);
    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setSellerFundsBpsesParams(
    //         sellerFundsBpses, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setCurationFundsBpsesParams(
    //     uint256 tokenId, 
    //     uint32[] calldata curationFundsBpses
    // ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setCurationFundsBpsesParams(
    //         curationFundsBpses,  
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setBpsParams(
    //     uint256 tokenId, 
    //     uint32 curationBps, 
    //     uint32 stakingBps
    // ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;
    
	// 	CurationHelpers.setBpsParams( 
    //         curationBps,
    //         stakingBps, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }), 
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    /// @inheritdoc IBardsHub
    function removeAllocation(
        address curator, 
        uint256 allocationId
    ) 
        external {
        delete _isToBeClaimedByAllocByCurator[curator][allocationId];
    }

    /// @inheritdoc IBardsHub
    function collect(
        DataTypes.SimpleDoCollectData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
        returns (address, uint256)
    {
        return CurationHelpers.collect(
            msg.sender,
            vars,
            _curationById
        );
    }

    /// @inheritdoc IBardsHub
    function collectWithSig(
        DataTypes.DoCollectWithSigData calldata vars
    )
        external
        override
        whenNotPaused
        returns (address, uint256)
    {
        unchecked {
            _validateRecoveredAddress(
                vars.encodecollectWithSigMessage(
                    sigNonces[vars.collector]++
                ),
                name(),
                vars.collector,
                vars.sig
            );
        }
        return CurationHelpers.collect(
            vars.collector,
            DataTypes.SimpleDoCollectData({
                curationId: vars.curationId,
                curationIds: vars.curationIds,
                collectMetaData: vars.collectMetaData,
                fromCuration: vars.fromCuration
            }),
            _curationById
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistCurrency(
        address currency, 
        bool toWhitelist
    ) 
        external 
        override 
        onlyGov 
    {
        _whitelistCurrency(currency, toWhitelist);
    }

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IBardsHub
    function isAuthForCurator(address operator, address curator)
        external
        view
        override
        returns (bool)
    {
        return (operator == curator ||
            isApprovedForAll(curator, operator));
    }

    /// @inheritdoc IBardsHub
    function isCurrencyWhitelisted(address currency) 
        external 
        view 
        override 
        returns (bool) 
    {
        return _currencyWhitelisted[currency];
    }

    /// @inheritdoc IBardsHub
    function isProfileCreatorWhitelisted(address profileCreator)
        external
        view
        override
        returns (bool)
    {
        return _profileCreatorWhitelisted[profileCreator];
    }

    /// @inheritdoc IBardsHub
    function isMarketModuleWhitelisted(address marketModule)
        external
        view
        override
        returns (bool)
    {
        return _marketModuleWhitelisted[marketModule];
    }

    /// @inheritdoc IBardsHub
    function isMinterModuleWhitelisted(address minterModule)
        external
        view
        override
        returns (bool)
    {
        return _minterModuleWhitelisted[minterModule];
    }

    /// @inheritdoc IBardsHub
    function getGovernance() 
        external 
        view 
        override 
        returns (address) {
            return _governance;
    }

    /// @inheritdoc IBardsHub
    function defaultProfile(address wallet)
        external
        view
        override
        returns (uint256)
    {
        return _defaultProfileByAddress[wallet];
    }

    /// @inheritdoc IBardsHub
    function getAllocationIdById(uint256 curationId)
        external
        view
        override
        returns (uint256)
    {
        return _curationById[curationId].allocationId;
    }

    /// @inheritdoc IBardsHub
    function getHandle(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return _curationById[profileId].handle;
    }

    /// @inheritdoc IBardsHub
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    /// @inheritdoc IBardsHub
    function getCuration(uint256 curationId)
        external
        view
        override
        returns (DataTypes.CurationStruct memory)
    {
        return _curationById[curationId];
    }

    /// @inheritdoc IBardsHub
    function getProfile(uint256 profileId)
        external
        view
        override
        returns (DataTypes.CurationStruct memory)
    {
        return _curationById[profileId];
    }

    /// @inheritdoc IBardsHub
    function getMarketModule(uint256 curationId)
        external
        view
        override
        returns (address)
    {
        return _curationById[curationId].marketModule;
    }

    /// @inheritdoc IBardsHub
    function getMinterMarketModule(uint256 curationId)
        external
        view
        override
        returns (address)
    {
        return _curationById[curationId].minterMarketModule;
    }

    /**
     * @notice TODO Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _curationById[tokenId].contentURI;
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _createCuration(DataTypes.CreateCurationData memory _vars)
        internal
        returns (uint256)
    {
        unchecked {
            uint256 curationId = ++_curationCounter;
            uint256 allocationId = ++_allocationCounter;
            _mint(_vars.to, curationId);
            _vars.curationId = curationId;
            
            // Not refer to other NFT contract.
            if (_vars.tokenContractPointed == address(0)){
                _vars.tokenContractPointed = address(this);
                _vars.tokenIdPointed = curationId;
            } else {
                // Get the owner of the specified token
                address tokenOwner = IERC721(_vars.tokenContractPointed).ownerOf(_vars.tokenIdPointed);
                // Ensure the caller is the owner or an approved operator
                require(
                    _isRegisteredAddress[msg.sender] == true || 
                    msg.sender == tokenOwner || 
                    IERC721(_vars.tokenContractPointed).isApprovedForAll(tokenOwner, msg.sender), 
                    "ONLY_TOKEN_OWNER_OR_OPERATOR"
                );
            }
            _vars.createCuration(
                allocationId,
                _cooldownBlocks,
                _getBardsStaking(),
                _curationData,
                _curationById,
                _marketModuleWhitelisted,
                _isToBeClaimedByAllocByCurator
            );

            return curationId;
        }
    }

    function _setCurationContentURI(
        uint256 curationId, 
        string calldata contentURI
    ) 
        internal 
    {
        if (bytes(contentURI).length > Constants.MAX_CURATION_CONTENT_URI_LENGTH)
            revert Errors.CurationContentURILengthInvalid();

        _curationById[curationId].contentURI = contentURI;

        emit Events.CurationContentURISet(
            curationId, 
            contentURI, 
            block.timestamp
        );
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _whitelistCurrency(address currency, bool toWhitelist) internal {
        if (currency == address(0)) revert Errors.ZeroAddress();
        bool prevWhitelisted = _currencyWhitelisted[currency];
        _currencyWhitelisted[currency] = toWhitelist;
        emit Events.ProtocolCurrencyWhitelisted(
            currency,
            prevWhitelisted,
            toWhitelist,
            block.timestamp
        );
    }

    /*
     * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
     * Note that the wallet address should either be the message sender or validated via a signature
     * prior to this function call.
     */
    function _setDefaultProfile(address wallet, uint256 profileId) internal {
        if (profileId > 0 && wallet != ownerOf(profileId))
            revert Errors.NotOwner();

        _defaultProfileByAddress[wallet] = profileId;

        emit Events.DefaultProfileSet(
            wallet, 
            profileId, 
            block.timestamp
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        override 
        whenNotPaused 
    {
        if (_defaultProfileByAddress[from] == tokenId) {
            _defaultProfileByAddress[from] = 0;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _validateCallerIsCurationOwnerOrApproved(
        uint256 curationId
    ) 
        internal 
        view 
    {
        if (_isRegisteredAddress[msg.sender] == true || _isApprovedOrOwner(msg.sender, curationId)) {
            return;
        }
        revert Errors.NotOwnerOrApproved();
    }

    function _validateCallerIsCurationOwner(
        uint256 curationId
    ) 
        internal 
        view 
    {
        if (msg.sender != ownerOf(curationId)) revert Errors.NotOwner();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        // require(msg.sender == _governance, 'not_gov');
    }

    function _existsAllocationId(uint256 allocationId) internal view returns (bool) {
        return _getBardsStaking().isAllocation(allocationId);
    }

    function _getBardsStaking() internal view returns (IBardsStaking) {
        return IBardsStaking(_registry[keccak256("BardsStaking")]);
    } 

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}