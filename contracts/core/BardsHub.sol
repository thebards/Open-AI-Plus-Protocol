// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './curations/BardsCurationBase.sol';
import './storages/BardsHubStorage.sol';
import '../interfaces/IBardsHub.sol';
import '../utils/DataTypes.sol';
import '../upgradeablity/VersionedInitializable.sol';
import '../utils/CurationHelpers.sol';
import './govs/BardsPausable.sol';


contract BardsHub is BardsCurationBase, BardsHubStorage, BardsPausable, VersionedInitializable, IBardsHub {
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
        address newGovernance
    ) external override initializer {
        super._initialize(name, symbol);
        _setState(DataTypes.ProtocolState.Paused);
        _setGovernance(newGovernance);
    }

	/// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /// @inheritdoc IBardsHub
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc IBardsHub
    function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
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
    function whitelistMarketModule(address marketModule, bool whitelist) external override onlyGov {
        _marketModuleWhitelisted[marketModule] = whitelist;
        emit Events.MarketModuleWhitelisted(marketModule, whitelist, block.timestamp);
    }

    /// *********************************
    /// *****PROFILE OWNER FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IBardsHub
    function createProfile(DataTypes.CreateCurationData calldata vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        if (!_profileCreatorWhitelisted[msg.sender]) revert Errors.ProfileCreatorNotWhitelisted();
        unchecked {
            uint256 profileId = ++_curationCounter;
            _mint(vars.to, profileId);
            CurationHelpers.createProfile(
                vars,
                profileId,
                _profileIdByHandleHash,
                _curationById,
                _isProfileById,
                _marketModuleWhitelisted
            );

            BardsCurationBase.initializeCuration(DataTypes.InitializeCurationData(profileId, vars.curationMetaData));
            return profileId;
        }
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfile(uint256 profileId) external override whenNotPaused {
        _setDefaultProfile(msg.sender, profileId);
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external
        override
        whenNotPaused
    {
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
                    )
                ),
                vars.wallet,
                vars.sig
            );
            _setDefaultProfile(vars.wallet, vars.profileId);
        }
    }
    
    /// @inheritdoc IBardsHub
    function setMarketModule(
        DataTypes.SetMarketModuleData calldata vars
    ) external override whenNotPaused {
        _validateCallerIsCurationOwner(vars.curationId);
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
    function setMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars)
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
                    )
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
    function setMintModule(
        DataTypes.SetMarketModuleData calldata vars
    ) external override whenNotPaused {
        _validateCallerIsCurationOwner(vars.curationId);
        CurationHelpers.setMintModule(
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
    function setMintModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars)
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
                    )
                ),
                owner,
                vars.sig
            );
        }
        CurationHelpers.setMintModule(
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
        _validateCallerIsProfileOwner(vars.profileId);
        return
            _createCuration(
                vars.to,
                vars.profileId,
                vars.tokenContractPointed,
                vars.tokenIdPointed,
                vars.contentURI,
                vars.marketModule,
                vars.marketModuleInitData,
                vars.mintModule,
                vars.mintModuleInitData,
                vars.curationMetaData
            );
    }

    /// @inheritdoc IBardsHub
    function createCurationWithSig(DataTypes.CreateCurationWithSigData calldata vars)
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
                            keccak256(bytes(vars.handle)),
                            keccak256(bytes(vars.contentURI)),
                            vars.marketModule,
                            keccak256(vars.marketModuleInitData),
                            vars.mintModule,
                            keccak256(vars.mintModuleInitData),
                            keccak256(vars.curationMetaData),
                            sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        return
            _createCuration(
                vars.to,
                vars.profileId,
                vars.tokenContractPointed,
                vars.tokenIdPointed,
                vars.contentURI,
                vars.marketModule,
                vars.marketModuleInitData,
                vars.mintModule,
                vars.mintModuleInitData,
                vars.curationMetaData
            );
    }

	/// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _createCuration(
        address to,
        uint256 profileId,
        address tokenContractPointed,
        uint256 tokenIdPointed,
        string memory contentURI,
        address marketModule,
        bytes memory marketModuleData,
        address mintModule,
        bytes memory mintModuleData,
        bytes memory curationMetaData
    ) internal returns (uint256) {
        unchecked {
            uint256 curationId = ++_curationCounter;
            _mint(to, curationId);
            CurationHelpers.createCuration(
                profileId,
                curationId,
                tokenContractPointed,
                tokenIdPointed,
                contentURI,
                marketModule,
                marketModuleData,
                mintModule,
                mintModuleData,
                _curationById,
                _isMintedByIdById,
                _marketModuleWhitelisted
            ); 
            BardsCurationBase.initializeCuration(DataTypes.InitializeCurationData(profileId, curationMetaData));
            return curationId;
        }
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
    }

    /*
     * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
     * Note that the wallet address should either be the message sender or validated via a signature
     * prior to this function call.
     */
    function _setDefaultProfile(address wallet, uint256 profileId) internal {
        if (profileId > 0 && wallet != ownerOf(profileId)) revert Errors.NotProfileOwner();

        _defaultProfileByAddress[wallet] = profileId;

        emit Events.DefaultProfileSet(wallet, profileId, block.timestamp);
    }

    function _validateCallerIsProfileOwner(uint256 profileId) internal view {
        if (msg.sender != ownerOf(profileId)) revert Errors.NotProfileOwner();
    }

    function _validateCallerIsCurationOwner(uint256 curationId) internal view {
        if (msg.sender != ownerOf(curationId)) revert Errors.NotCurationOwner();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}