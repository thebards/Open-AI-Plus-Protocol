// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './curations/BardsCurationBase.sol';
import './storages/BardsHubStorage.sol';
import '../interfaces/IBardsHub.sol';
import '../utils/DataTypes.sol';
import '../upgradeablity/VersionedInitializable.sol';
import '../utils/CurationHelpers.sol';
import './govs/BardsPausable.sol';


contract BardsHub is
    BardsCurationBase,
    BardsHubStorage,
    BardsPausable,
    VersionedInitializable,
    IBardsHub
{
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
    function setEmergencyAdmin(address newEmergencyAdmin)
        external
        override
        onlyGov
    {
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
            _mint(vars.to, profileId);
            vars.profileId = profileId;
            CurationHelpers.createProfile(
                vars,
                _profileIdByHandleHash,
                _curationById,
                _isProfileById,
                _marketModuleWhitelisted
            );

            initializeCuration(
                DataTypes.InitializeCurationData({
                    tokenId: profileId,
                    curationData: vars.curationMetaData
                })
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
                    )
                ),
                vars.wallet,
                vars.sig
            );
            _setDefaultProfile(vars.wallet, vars.profileId);
        }
    }

    /// @inheritdoc IBardsHub
    function setMarketModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
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
    function setMintModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
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
    function setMintModuleWithSig(
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
        return _createCuration(vars);
    }

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

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
    function getGovernance() external view override returns (address) {
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
    function getMintModule(uint256 curationId)
        external
        view
        override
        returns (address)
    {
        return _curationById[curationId].mintModule;
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
            _mint(_vars.to, curationId);
            _vars.curationId = curationId;
            CurationHelpers.createCuration(
                _vars,
                _curationById,
                _isMintedByIdById,
                _marketModuleWhitelisted
            );
            initializeCuration(
                DataTypes.InitializeCurationData(
                    _vars.profileId,
                    _vars.curationMetaData
                )
            );
            return curationId;
        }
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

    /*
     * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
     * Note that the wallet address should either be the message sender or validated via a signature
     * prior to this function call.
     */
    function _setDefaultProfile(address wallet, uint256 profileId) internal {
        if (profileId > 0 && wallet != ownerOf(profileId))
            revert Errors.NotProfileOwner();

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