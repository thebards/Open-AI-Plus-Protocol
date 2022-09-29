// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {CodeUtils} from './CodeUtils.sol';
import {MathUtils} from './MathUtils.sol';
import {IMarketModule} from '../interfaces/markets/IMarketModule.sol';
import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';

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
    using SafeMath for uint256;
	using CurationHelpers for DataTypes.CurationStruct;
	using CurationHelpers for DataTypes.CreateCurationData;

	/**
     * @notice Executes the logic to create a profile with the given parameters to the given address.
     *
     * @param _vars The CreateProfileData struct.
     * @param _allocationId allocationg id
     * @param _minimalCooldownBlocks minimal cool down blocks
     * @param _bardsStaking The address of BardsStaking contract
     * @param _curationData The storage reference to the mapping of curation data.
     * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
     * @param _curationById The storage reference to the mapping of profile structs by IDs.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     * @param _isToBeClaimedByAllocByCurator The storage reference to the mapping of claim status of allocation.
     */
    function createProfile(
        DataTypes.CreateCurationData memory _vars,
        uint256 _allocationId,
        uint32 _minimalCooldownBlocks,
        IBardsStaking _bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => bool) storage _marketModuleWhitelisted,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) external {
        _validateHandle(_vars.handle);
        bytes32 handleHash = keccak256(bytes(_vars.handle));
        if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleToken();

        _profileIdByHandleHash[handleHash] = _vars.profileId;

        _curationById[_vars.profileId].curationType = _vars.curationType;
        _curationById[_vars.profileId].handle = _vars.handle;
        _curationById[_vars.profileId].contentURI = _vars.contentURI;
        _curationById[_vars.profileId].tokenContractPointed = _vars.tokenContractPointed;
		_curationById[_vars.profileId].tokenIdPointed = _vars.tokenIdPointed;
        _curationById[_vars.profileId].curationFrom = _vars.curationFrom;

        bytes memory marketModuleReturnData = _vars.marketModuleInitData;
        if (_vars.marketModule != address(0)) {
            _curationById[_vars.profileId].marketModule = _vars.marketModule;
            marketModuleReturnData = _initMarketModule(
				_vars.tokenContractPointed, 
                _vars.tokenIdPointed,
                _vars.marketModule,
                _vars.marketModuleInitData,
                _marketModuleWhitelisted
            );
        }

		bytes memory minterMarketModuleReturnData = _vars.minterMarketModuleInitData;
        if (_vars.minterMarketModule != address(0)) {
            _curationById[_vars.profileId].minterMarketModule = _vars.minterMarketModule;
            // mint module is also a market module, whose minter is different.
			minterMarketModuleReturnData = _initMarketModule(
				_vars.tokenContractPointed,
                _vars.tokenIdPointed,
				_vars.minterMarketModule,
				_vars.minterMarketModuleInitData,
                _marketModuleWhitelisted
            );
        }

        _initCurationRecipientsParams(
            DataTypes.InitializeCurationData({
                tokenId: _vars.profileId,
                curationData: _vars.curationMetaData
            }), 
            _vars.to,
            _allocationId,
            _minimalCooldownBlocks, 
            _bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );

        _emitProfileCreated(
            _vars.profileId, 
            _vars,
            marketModuleReturnData,
            minterMarketModuleReturnData
        );
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
    function setMinterMarketModule(
		uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        DataTypes.CurationStruct storage _curation,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        if (marketModule != _curation.minterMarketModule) {
            _curation.minterMarketModule = marketModule;
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
			 
        emit Events.MinterMarketModuleSet(
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
     * @param _vars The CreateProfileData struct.
     * @param _allocationId allocationg id
     * @param _minimalCooldownBlocks minimal cool down blocks
     * @param _bardsStaking The address of BardsStaking contract
     * @param _curationData The storage reference to the mapping of curation data.
     * @param _curationById The storage reference to the mapping of curations by token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
     * @param _isToBeClaimedByAllocByCurator The storage reference to the mapping of claim status of allocation.
     */
    function createCuration(
        DataTypes.CreateCurationData memory _vars,
        uint256 _allocationId,
        uint32 _minimalCooldownBlocks,
        IBardsStaking _bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => bool) storage _marketModuleWhitelisted,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) external {
        _curationById[_vars.curationId].curationType = _vars.curationType;
        _curationById[_vars.curationId].contentURI = _vars.contentURI;
		_curationById[_vars.curationId].tokenContractPointed = _vars.tokenContractPointed;
		_curationById[_vars.curationId].tokenIdPointed = _vars.tokenIdPointed;
		_curationById[_vars.curationId].curationFrom = _vars.curationFrom;
        _curationById[_vars.curationId].allocationId = _allocationId;

        if (_vars.marketModule != address(0)) {
            _initMarketModule(
				_vars.tokenContractPointed, 
                _vars.tokenIdPointed,
                _vars.marketModule,
                _vars.marketModuleInitData,
                _marketModuleWhitelisted
            );
            _curationById[_vars.curationId].marketModule = _vars.marketModule;
        }
        if (_vars.minterMarketModule != address(0)) {
			_initMarketModule(
				_vars.tokenContractPointed,
                _vars.tokenIdPointed,
				_vars.minterMarketModule,
				_vars.minterMarketModuleInitData,
                _marketModuleWhitelisted
            );
            _curationById[_vars.curationId].minterMarketModule = _vars.minterMarketModule;
        }

        _initCurationRecipientsParams(
            DataTypes.InitializeCurationData({
                tokenId: _vars.curationId,
                curationData: _vars.curationMetaData
            }),
            _vars.to,
            _allocationId,
            _minimalCooldownBlocks, 
            _bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );

        emit Events.CurationCreated(
            _vars.profileId,
            _vars.curationId, 
            _vars.contentURI,
            _vars.marketModule,
            _vars.marketModuleInitData,
            _vars.minterMarketModule,
            _vars.minterMarketModuleInitData,
            block.timestamp
        );
    }

    /**
     * @notice Collects the given curation, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *
     * @param _vars A struct of DoCollectData.
     *
     */
    function collect(
        address collector,
        DataTypes.SimpleDoCollectData memory _vars,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById
    ) 
        external
        returns (address, uint256)
    {
        // Avoids stack too deep
        DataTypes.CurationStruct storage curation = _curationById[_vars.curationId];
        address marketModule;
        if (_vars.fromCuration == true){
            marketModule = curation.minterMarketModule;
        } else{
            marketModule = curation.marketModule;
        }
        
        if (marketModule == address(0)) {
            revert Errors.MarketZeroAddress();
        }

        (
            address retTokenContract, 
            uint256 retTokenId
        ) = IMarketModule(marketModule).collect(
            collector,
            _vars.curationId,
            curation.tokenContractPointed,
            curation.tokenIdPointed,
            _vars.curationIds,
            _vars.collectMetaData
        );

        emit Events.Collected(
            collector,
            _vars.curationId,
            retTokenContract,
            retTokenId,
            _vars.collectMetaData,
            block.timestamp
        );

        return (retTokenContract, retTokenId);
    }

    function setCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		external
        returns (bytes memory)
	{
        return _setCurationRecipientsParams(
            vars,
            owner,
            newAllocationId,
            minimalCooldownBlocks,
            bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );
    }

    function _initCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		private
        returns (bytes memory)
	{
		require(
            _curationData[vars.tokenId].updatedAtBlock == 0 ||
                _curationData[vars.tokenId].updatedAtBlock.add(uint256(minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

		DataTypes.CurationData memory curationData = CodeUtils.decodeCurationMetaData(vars.curationData);

		require(
			curationData.sellerFundsBpses.length == curationData.sellerFundsRecipients.length, 
			"sellerFundsRecipients and sellerFundsBpses must have same length."
		);
		require(
			curationData.curationFundsRecipients.length == curationData.curationFundsBpses.length, 
			"curationFundsRecipients and curationFundsBpses must have same length."
		);
		require(
			MathUtils.sum(MathUtils.uint32To256Array(curationData.sellerFundsBpses)) + 
			MathUtils.sum(MathUtils.uint32To256Array(curationData.curationFundsBpses)) == Constants.MAX_BPS, 
			"The sum of sellerFundsBpses and curationFundsBpses must be equal to 1000000."
		);
		require(
			curationData.curationBps + curationData.stakingBps <= Constants.MAX_BPS, 
			"curationBps + stakingBps <= 100%"
		);

		_curationData[vars.tokenId] = DataTypes.CurationData({
			sellerFundsRecipients: curationData.sellerFundsRecipients,
			curationFundsRecipients: curationData.curationFundsRecipients,
			sellerFundsBpses: curationData.sellerFundsBpses,
			curationFundsBpses: curationData.curationFundsBpses,
			curationBps: curationData.curationBps,
			stakingBps: curationData.stakingBps,
			updatedAtBlock: block.number
		});

        bardsStaking.allocate(
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.tokenId,
                recipientsMeta: vars.curationData,
                allocationId: newAllocationId
            })
        );
        _curationById[vars.tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

        emit Events.CurationUpdated(
            vars.tokenId,
            vars.curationData,
            block.timestamp
        );

        return vars.curationData;
	}


    function _setCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		private
        returns (bytes memory)
	{
		require(
            _curationData[vars.tokenId].updatedAtBlock == 0 ||
                _curationData[vars.tokenId].updatedAtBlock.add(uint256(minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

		DataTypes.CurationData memory curationData = CodeUtils.decodeCurationMetaData(vars.curationData);

		require(
			curationData.sellerFundsBpses.length == curationData.sellerFundsRecipients.length, 
			"sellerFundsRecipients and sellerFundsBpses must have same length."
		);
		require(
			curationData.curationFundsRecipients.length == curationData.curationFundsBpses.length, 
			"curationFundsRecipients and curationFundsBpses must have same length."
		);
		require(
			MathUtils.sum(MathUtils.uint32To256Array(curationData.sellerFundsBpses)) + 
			MathUtils.sum(MathUtils.uint32To256Array(curationData.curationFundsBpses)) == Constants.MAX_BPS, 
			"The sum of sellerFundsBpses and curationFundsBpses must be equal to 1000000."
		);
		require(
			curationData.curationBps + curationData.stakingBps <= Constants.MAX_BPS, 
			"curationBps + stakingBps <= 100%"
		);

		_curationData[vars.tokenId] = DataTypes.CurationData({
			sellerFundsRecipients: curationData.sellerFundsRecipients,
			curationFundsRecipients: curationData.curationFundsRecipients,
			sellerFundsBpses: curationData.sellerFundsBpses,
			curationFundsBpses: curationData.curationFundsBpses,
			curationBps: curationData.curationBps,
			stakingBps: curationData.stakingBps,
			updatedAtBlock: block.number
		});

        bardsStaking.closeAndAllocate(
            _curationById[vars.tokenId].allocationId,
            vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.tokenId,
                recipientsMeta: vars.curationData,
                allocationId: newAllocationId
            })
        );
        _curationById[vars.tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

        emit Events.CurationUpdated(
            vars.tokenId,
            vars.curationData,
            block.timestamp
        );

        return vars.curationData;
	}

	function setSellerFundsRecipientsParams(
		address[] calldata sellerFundsRecipients,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            _curationData[_vars.tokenId].sellerFundsBpses.length == sellerFundsRecipients.length, 
            "sellerFundsRecipients and sellerFundsBpses must have same length."
        );

		_curationData[_vars.tokenId].sellerFundsRecipients = sellerFundsRecipients;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);
        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationSellerFundsRecipientsUpdated(
			_vars.tokenId, 
			sellerFundsRecipients, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationFundsRecipientsParams(
        uint256[] calldata curationFundsRecipients,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            curationFundsRecipients.length == _curationData[_vars.tokenId].curationFundsBpses.length, 
            "curationFundsRecipients and curationFundsBpses must have same length."
        );

		_curationData[_vars.tokenId].curationFundsRecipients = curationFundsRecipients;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationFundsRecipientsUpdated(
			_vars.tokenId, 
			curationFundsRecipients, 
			block.timestamp
		);

        return metaData;
	}

	function setSellerFundsBpsesParams(
        uint32[] calldata sellerFundsBpses,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            sellerFundsBpses.length == _curationData[_vars.tokenId].sellerFundsRecipients.length, 
            "sellerFundsRecipients and sellerFundsBpses must have same length."
        );

        require(
            MathUtils.sum(MathUtils.uint32To256Array(sellerFundsBpses)) + 
            MathUtils.sum(MathUtils.uint32To256Array(_curationData[_vars.tokenId].curationFundsBpses)) == Constants.MAX_BPS, 
            "The sum of sellerFundsBpses and curationFundsBpses must be equal to 100%."
        );

		_curationData[_vars.tokenId].sellerFundsBpses = sellerFundsBpses;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationSellerFundsBpsesUpdated(
			_vars.tokenId, 
			sellerFundsBpses, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationFundsBpsesParams( 
        uint32[] calldata curationFundsBpses,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory) 
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            MathUtils.sum(MathUtils.uint32To256Array(_curationData[_vars.tokenId].sellerFundsBpses)) + 
            MathUtils.sum(MathUtils.uint32To256Array(curationFundsBpses)) == Constants.MAX_BPS, 
            "The sum of sellerFundsBpses and curationFundsBpses must be equal to 100%."
        );

		_curationData[_vars.tokenId].curationFundsBpses = curationFundsBpses;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;
        
        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationFundsBpsesUpdated(
			_vars.tokenId, 
			curationFundsBpses, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationBpsParams(
        uint32 curationBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(curationBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

        require(
            curationBps + _curationData[_vars.tokenId].stakingBps <= Constants.MAX_BPS, 
            "curationBps + stakingBps <= 100%"
        );

		_curationData[_vars.tokenId].curationBps = curationBps;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationBpsUpdated(
            _vars.tokenId, 
            curationBps, 
            block.timestamp
        );

        return metaData;
	}

	function setStakingBpsParams(
        uint32 stakingBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );
		require(stakingBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");
        require(
            _curationData[_vars.tokenId].curationBps + stakingBps <= Constants.MAX_BPS, 
            "curationBps + stakingBps <= 100%"
        );

		_curationData[_vars.tokenId].stakingBps = stakingBps;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.StakingBpsUpdated(_vars.tokenId, stakingBps, block.timestamp);

        return metaData;
	}


	function setBpsParams(
        uint32 curationBps, 
        uint32 stakingBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory) 
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );
		require(curationBps + stakingBps <= Constants.MAX_BPS, 'curationBps + stakingBps <= 100%');
		
		_curationData[_vars.tokenId].updatedAtBlock = block.number;
		_curationData[_vars.tokenId].curationBps = curationBps;
		emit Events.CurationBpsUpdated(_vars.tokenId, curationBps, block.timestamp);

		_curationData[_vars.tokenId].stakingBps = stakingBps;
		emit Events.StakingBpsUpdated(_vars.tokenId, stakingBps, block.timestamp);

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

        return metaData;
	}

	function _initMarketModule(
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) 
        private 
        returns (bytes memory) 
    {
        if (!_marketModuleWhitelisted[marketModule]) revert Errors.MarketModuleNotWhitelisted();
        return IMarketModule(marketModule).initializeModule(
            tokenContract, 
            tokenId, 
            marketModuleInitData
        );
    }

    function _emitProfileCreated(
        uint256 profileId,
        DataTypes.CreateCurationData memory vars,
        bytes memory marketModuleReturnData,
		bytes memory minterMarketModuleReturnData
    ) 
        private 
    {
        emit Events.ProfileCreated(
            profileId,
            msg.sender, // Creator is always the msg sender
            vars.to,
            vars.handle,
            vars.contentURI,
            vars.marketModule,
            marketModuleReturnData,
            vars.minterMarketModule,
            minterMarketModuleReturnData,
            block.timestamp
        );
    }

	function _validateHandle(
        string memory handle
    ) 
        private 
        pure 
    {
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