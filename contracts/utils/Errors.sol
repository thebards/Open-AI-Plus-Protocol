// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
	error CannotInitImplementation();
    error Initialized();
    error SignatureExpired();
    error ZeroSpender();
    error ZeroPrice();
    error ZeroAddress();
    error SignatureInvalid();
    error NotOwnerOrApproved();
    error NotHub();
    error TokenDoesNotExist();
    error NotGovernance();
    error NotGovernanceOrEmergencyAdmin();
    error EmergencyAdminCannotUnpause();
    error CallerNotWhitelistedModule();
    error MarketModuleNotWhitelisted();
    error MinterModuleNotWhitelisted();
    error CurrencyNotWhitelisted();
    error ProfileCreatorNotWhitelisted();
    error NotOwner();
    error CurationDoesNotExist();
    error HandleToken();
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error BlockNumberInvalid();
    error ArrayMismatch();
    error NotWhitelisted();
    error CurationContentURILengthInvalid();
    error NoAllowance();

    // Market Errors
    error InitParamsInvalid();
    error MarketZeroAddress();
    error CollectExpired();
    error ModuleDataMismatch();
    error MintLimitExceeded();
    error TradeNotAllowed();

    // Pausable Errors
    error Paused();
    error CurationPaused();
}