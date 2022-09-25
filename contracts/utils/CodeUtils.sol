// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "./DataTypes.sol";

library CodeUtils {
	
	function decodeCurationMetaData(
		bytes memory curationMetaData
	)
		public
		pure
		returns (DataTypes.CurationData memory)
	{
		    (
            address[] memory sellerFundsRecipients,
            uint256[] memory curationFundsRecipients,
            uint32[] memory sellerFundsBpses,
            uint32[] memory curationFundsBpses,
            uint32 curationBps,
            uint32 stakingBps
        ) = abi.decode(
            curationMetaData, 
            (address[], uint256[], uint32[], uint32[], uint32, uint32)
        );

		return DataTypes.CurationData({
			sellerFundsRecipients: sellerFundsRecipients,
			curationFundsRecipients: curationFundsRecipients,
			sellerFundsBpses: sellerFundsBpses,
			curationFundsBpses: curationFundsBpses,
			curationBps: curationBps,
			stakingBps: stakingBps
		});
	}
}