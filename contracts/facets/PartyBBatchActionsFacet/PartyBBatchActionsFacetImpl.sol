// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibMuon.sol";
import "../../libraries/LibSolvency.sol";
import "../../libraries/LibPartyB.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/AccountStorage.sol";

library PartyBBatchActionsFacetImpl {

	function fillCloseRequests(
		uint256[] memory quoteIds,
		uint256[] memory filledAmounts,
		uint256[] memory closedPrices,
		PairUpnlAndPricesSig memory upnlSig
	) internal {
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		require(
			quoteIds.length == filledAmounts.length && quoteIds.length == closedPrices.length && quoteIds.length > 0,
			"PartyBFacet: Invalid length"
		);
		Quote storage firstQuote = QuoteStorage.layout().quotes[quoteIds[0]];
		LibMuon.verifyPairUpnlAndPrices(upnlSig, firstQuote.partyB, firstQuote.partyA, quoteIds);
		LibSolvency.isSolventAfterClosePosition(
			quoteIds,
			filledAmounts,
			closedPrices,
			upnlSig.prices,
			upnlSig.upnlPartyB,
			upnlSig.upnlPartyA,
			firstQuote.partyB,
			firstQuote.partyA
		);
		accountLayout.partyBNonces[firstQuote.partyB][firstQuote.partyA] += 1;
		accountLayout.partyANonces[firstQuote.partyA] += 1;
		for (uint8 i = 0; i < quoteIds.length; i++) {
			uint256 quoteId = quoteIds[i];
			uint256 filledAmount = filledAmounts[i];
			uint256 closedPrice = closedPrices[i];
			Quote storage quote = QuoteStorage.layout().quotes[quoteId];
			require(quote.partyB == msg.sender);
			require(firstQuote.partyA == quote.partyA);
			require(!MAStorage.layout().liquidationStatus[quote.partyA], "PartyBFacet: PartyA isn't solvent");
			require(!MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA], "PartyBFacet: PartyB isn't solvent");
			LibPartyB.fillCloseRequest(quoteId, filledAmount, closedPrice);
		}
	}

}
