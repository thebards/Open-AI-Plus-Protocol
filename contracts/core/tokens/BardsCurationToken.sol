// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsCurationToken.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import '../storages/TokenStorage.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '../../utils/Events.sol';
import '../../utils/Errors.sol';
import '../govs/ContractRegistrar.sol';
import "hardhat/console.sol";

/**
 * @title BardsCurationToken contract
 * @author TheBards Protocol
 * 
 * @notice This is the implementation of the ERC20 Bards Curation Token.
 * The implementation exposes a Permit() function to allow for a spender to send a signed message
 * and approve funds to a spender following EIP2612 to make integration with other contracts easier.
 *
 * The token is initially owned by the deployer address that can mint tokens to create the initial
 * distribution. For convenience, an initial supply can be passed in the constructor that will be
 * assigned to the deployer.
 *
 */
contract BardsCurationToken is TokenStorage, ContractRegistrar, ERC20Burnable {
    using SafeMath for uint256;
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    mapping(address => bool) private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Only minter can call");
        _;
    }

    /**
     * @notice Bards Curation Token Contract Constructor.
     * @param _initialSupply Initial supply of BCT
     */
    constructor(address _HUB, uint256 _initialSupply) ERC20("Bards Curation Token", "BCT") {
        if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        ContractRegistrar._initialize(_HUB);
        address gov = bardsHub().getGovernance();
        // The Governor has the initial supply of tokens
        _mint(gov, _initialSupply);
        // The Governor is the default minter
        _addMinter(gov);
        // HUB is minter too
        _addMinter(_HUB);
        _addMinter(msg.sender);

    }

    function permit(
        DataTypes.BCTPermitWithSigData calldata _vars
    ) external {
        if (_vars.owner == address(0) || _vars.spender == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _vars.owner,
                            _vars.spender,
                            _vars.value,
                            sigNonces[_vars.owner]++,
                            _vars.sig.deadline
                        )
                    ),
                    name()
                ),
                _vars.owner,
                _vars.sig
            );
        }
        _approve(_vars.owner, _vars.spender, _vars.value);
    }

    function addMinter(
        address _account
    ) 
        external 
        onlyGov 
    {
        _addMinter(_account);
    }

    function removeMinter(
        address _account
    ) 
        external 
        onlyGov 
    {
        _removeMinter(_account);
    }

    function renounceMinter() external {
        _removeMinter(msg.sender);
    }

    function mint(
        address _to, 
        uint256 _amount
    ) 
        external 
        onlyMinter 
    {
        _mint(_to, _amount);
    }

    function isMinter(
        address _account
    ) 
        public 
        view 
        returns (bool) 
    {
        return _minters[_account];
    }

    /**
     * @notice Add a new minter.
     * @param _account Address of the minter
     */
    function _addMinter(
        address _account
    ) 
        private 
    {
        _minters[_account] = true;
        emit Events.MinterAdded(_account, block.timestamp);
    }

    /**
     * @notice Remove a minter.
     * @param _account Address of the minter
     */
    function _removeMinter(
        address _account
    )
        private 
    {
        _minters[_account] = false;
        emit Events.MinterRemoved(_account, block.timestamp);
    }
}