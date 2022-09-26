// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './curations/BardsCurationBase.sol';
import './storages/BardsHubStorage.sol';
import '../interfaces/IBardsHub.sol';
import '../utils/DataTypes.sol';
import '../interfaces/tokens/IBardsStaking.sol';
import '../upgradeablity/VersionedInitializable.sol';
import '../utils/CurationHelpers.sol';
import '../utils/Errors.sol';
import './govs/BardsPausable.sol';
import "hardhat/console.sol";


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
    uint256 internal constant REVISION = 1;

    // /**
    //  * @dev The constructor sets the immutable bardsDaoData implementations.
    //  *
    //  * @param bardsDaoDataImpl The bardsDaoData NFT implementation address.
    //  */
    // constructor(address bardsDaoDataImpl) {
    //     if (bardsDaoDataImpl == address(0)) revert Errors.InitParamsInvalid();
    // }
    
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
            
            CurationHelpers.createProfile(
                vars,
                _profileIdByHandleHash,
                _curationById,
                _isProfileById,
                _marketModuleWhitelisted
            );

            _initializeCuration(
                DataTypes.InitializeCurationData({
                    tokenId: profileId,
                    curationData: vars.curationMetaData
                })
            ); 

            // init allocation
            _curationById[profileId].allocationId = allocationId;
            _getBardsStaking().allocate(
                DataTypes.CreateAllocateData({
                    curator: vars.to,
                    curationId: profileId,
                    recipientsMeta: vars.curationMetaData,
                    allocationId: allocationId
                })
            );
            _isToBeClaimedByAllocByCurator[vars.to][allocationId] = true;
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
    ) external override whenNotPaused {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH,
                            vars.wallet,
                            vars.profileId,
                            sigNonces[vars.wallet]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_CURATION_CONTENT_URI_WITH_SIG_TYPEHASH,
                            vars.curationId,
                            keccak256(bytes(vars.contentURI)),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_ALLOCATION_ID_WITH_SIG_TYPEHASH,
                            vars.curationId,
                            vars.allocationId,
                            keccak256(vars.curationMetaData),
                            vars.stakeToCuration,
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_MARKET_MODULE_WITH_SIG_TYPEHASH,
                            vars.curationId,
                            vars.tokenContract,
                            vars.tokenId,
                            vars.marketModule,
                            keccak256(vars.marketModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_MARKET_MODULE_WITH_SIG_TYPEHASH,
                            vars.curationId,
                            vars.tokenContract,
                            vars.tokenId,
                            vars.marketModule,
                            keccak256(vars.marketModuleInitData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            CREATE_CURATION_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.tokenContractPointed,
                            vars.tokenIdPointed,
                            keccak256(bytes(vars.contentURI)),
                            vars.marketModule,
                            keccak256(vars.marketModuleInitData),
                            vars.minterMarketModule,
                            keccak256(vars.minterMarketModuleInitData),
                            keccak256(vars.curationMetaData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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
                curationMetaData: vars.curationMetaData
            }
        ));
    }

    /**
    * @notice Initializes a curation with the specified parameters. 
    */
	function _initializeCuration(
        DataTypes.InitializeCurationData memory _vars
    )
		internal
	{
        _validateCallerIsCurationOwnerOrApproved(_vars.tokenId);

		CurationHelpers.setCurationRecipientsParams(_vars, _cooldownBlocks, _curationData);
	}

    /// @inheritdoc IBardsHub
	function updateCuration(
        DataTypes.InitializeCurationData memory _vars
    )
		external
		override
	{

        _validateCallerIsCurationOwnerOrApproved(_vars.tokenId);
        
		bytes memory metaData = CurationHelpers.setCurationRecipientsParams(_vars, _cooldownBlocks, _curationData);

        // reset allocation for curation
        address owner = ownerOf(_vars.tokenId);
        uint256 newAllocationId = ++_allocationCounter;

        _getBardsStaking().closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;
	}

    /// @inheritdoc IBardsHub
	function setSellerFundsRecipientsParams(
		uint256 tokenId, 
		address[] calldata sellerFundsRecipients
	) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);

        bytes memory metaData = CurationHelpers.setSellerFundsRecipientsParams(
            tokenId, 
            sellerFundsRecipients, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

	}

    /// @inheritdoc IBardsHub
	function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) 
		external 
		virtual 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);
        bytes memory metaData = CurationHelpers.setCurationFundsRecipientsParams(
            tokenId, 
            curationFundsRecipients, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

	}

    /// @inheritdoc IBardsHub
	function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);
        bytes memory metaData = CurationHelpers.setSellerFundsBpsesParams(
            tokenId, 
            sellerFundsBpses, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

	}

    /// @inheritdoc IBardsHub
	function setCurationFundsBpsesParams(
        uint256 tokenId, 
        uint32[] calldata curationFundsBpses
    ) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);

        bytes memory metaData = CurationHelpers.setCurationFundsBpsesParams(
            tokenId, 
            curationFundsBpses, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

	}

    /// @inheritdoc IBardsHub
	function setCurationBpsParams(
        uint256 tokenId, 
        uint32 curationBps
    ) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);

        bytes memory metaData = CurationHelpers.setCurationBpsParams(
            tokenId, 
            curationBps, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

	}

    /// @inheritdoc IBardsHub
	function setStakingBpsParams(
        uint256 tokenId, 
        uint32 stakingBps
    ) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);

		bytes memory metaData = CurationHelpers.setStakingBpsParams(
            tokenId, 
            stakingBps, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;
	}

    /// @inheritdoc IBardsHub
	function setBpsParams(
        uint256 tokenId, 
        uint32 curationBps, 
        uint32 stakingBps
    ) 
		external 
		override 
	{
        _validateCallerIsCurationOwnerOrApproved(tokenId);
    
		bytes memory metaData = CurationHelpers.setBpsParams(
            tokenId, 
            curationBps, 
            stakingBps, 
            _cooldownBlocks, 
            _curationData
        );

        // reset allocation for curation
        address owner = ownerOf(tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
        _getBardsStaking().closeAndAllocate(
            _curationById[tokenId].allocationId,
            tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: tokenId,
                recipientsMeta: metaData,
                allocationId: newAllocationId
            })
        );
        _curationById[tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;
	}

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
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            COLLECT_WITH_SIG_TYPEHASH,
                            vars.curationId,
                            keccak256(vars.collectMetaData),
                            sigNonces[vars.collector]++,
                            vars.sig.deadline
                        )
                    ),
                    name()
                ),
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

    /// @inheritdoc IBardsHub
    function getContentURI(uint256 curationId)
        external
        view
        override
        returns (string memory)
    {
        return _curationById[curationId].contentURI;
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
                require(_isRegisteredAddress[msg.sender] == true || msg.sender == tokenOwner || IERC721(_vars.tokenContractPointed).isApprovedForAll(tokenOwner, msg.sender), "ONLY_TOKEN_OWNER_OR_OPERATOR");
            }
            CurationHelpers.createCuration(
                _vars,
                _curationById,
                _isMintedByIdById,
                _marketModuleWhitelisted
            );
            _initializeCuration(
                DataTypes.InitializeCurationData(
                    curationId,
                    _vars.curationMetaData
                )
            );

            // init allocation
            _curationById[curationId].allocationId = allocationId;
            _getBardsStaking().allocate(
                DataTypes.CreateAllocateData({
                    curator: msg.sender,
                    curationId: curationId,
                    recipientsMeta: _vars.curationMetaData,
                    allocationId: allocationId
                })
            );
            _isToBeClaimedByAllocByCurator[_vars.to][allocationId] = true;
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

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}