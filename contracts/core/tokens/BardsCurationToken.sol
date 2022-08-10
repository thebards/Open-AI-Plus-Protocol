// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsCurationToken.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import '../storages/TokenStorage.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '../../utils/Events.sol';
import '../../utils/Errors.sol';

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
contract BardsCurationToken is ERC20Burnable, IBardsCurationToken, TokenStorage {
    using SafeMath for uint256;
    
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    mapping(address => bool) private _minters;
    address HUB;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Only minter can call");
        _;
    }

    modifier onlyHub() {
        require(msg.sender == HUB, "Only HUB can call");
        _;
    }

    /**
     * @dev Bards Curation Token Contract Constructor.
     * @param _initialSupply Initial supply of GRT
     */
    constructor(address _HUB, uint256 _initialSupply) ERC20("Bards Curation Token", "BCT") {
        if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        HUB = _HUB;
        // The Governor has the initial supply of tokens
        _mint(msg.sender, _initialSupply);
        // The Governor is the default minter
        _addMinter(msg.sender);
        // HUB is minter too
        _addMinter(HUB);
    }

    /// @inheritdoc IBardsCurationToken
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (_owner == address(0) || _spender == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _owner,
                            _spender,
                            _value,
                            sigNonces[_owner]++,
                            sig.deadline
                        )
                    ),
                    name()
                ),
                _owner,
                sig
            );
        }
        _approve(_owner, _spender, _value);
    }

    /// @inheritdoc IBardsCurationToken
    function addMinter(address _account) external onlyHub {
        _addMinter(_account);
    }

    /// @inheritdoc IBardsCurationToken
    function removeMinter(address _account) external onlyHub {
        _removeMinter(_account);
    }

    /// @inheritdoc IBardsCurationToken
    function renounceMinter() external {
        _removeMinter(msg.sender);
    }

    /// @inheritdoc IBardsCurationToken
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    /// @inheritdoc IBardsCurationToken
    function isMinter(address _account) public view returns (bool) {
        return _minters[_account];
    }

    /**
     * @dev Add a new minter.
     * @param _account Address of the minter
     */
    function _addMinter(address _account) private {
        _minters[_account] = true;
        emit MinterAdded(_account, block.timestamp);
    }

    /**
     * @dev Remove a minter.
     * @param _account Address of the minter
     */
    function _removeMinter(address _account) private {
        _minters[_account] = false;
        emit MinterRemoved(_account, block.timestamp);
    }
}