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

library OracleLessActionsFacetImpl {
	function lockQuotes(uint256[] memory quoteIds) internal {
		for (uint8 i = 0; i < quoteIds.length; i++) {
			Quote storage quote = QuoteStorage.layout().quotes[quoteIds[i]];
			require(!MAStorage.layout().liquidationStatus[quote.partyA], "OracleLessActionsFacet: PartyA isn't solvent");
			require(!MAStorage.layout().partyBLiquidationStatus[msg.sender][quote.partyA], "OracleLessActionsFacet: PartyB isn't solvent");
			require(AccountStorage.layout().boundPartyB[quote.partyA] == msg.sender, "OracleLessActionsFacet: PartyB is not bounded to this partyA");
			LibPartyB.lockQuote(quoteIds[i]);
		}
	}
	function openPositions(
		uint256[] memory quoteIds,
		uint256[] memory filledAmounts,
		uint256[] memory openedPrices
	) internal returns (uint256[] memory currentIds) {
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
		require(
			quoteIds.length == filledAmounts.length && quoteIds.length == openedPrices.length && quoteIds.length > 0,
			"OracleLessActionsFacet: Invalid length"
		);
		Quote storage firstQuote = QuoteStorage.layout().quotes[quoteIds[0]];
		require(accountLayout.suspendedAddresses[firstQuote.partyA] == false, "OracleLessActionsFacet: PartyA is suspended");
		require(!accountLayout.suspendedAddresses[firstQuote.partyB], "OracleLessActionsFacet: Sender is Suspended");
		require(!appLayout.partyBEmergencyStatus[firstQuote.partyB], "OracleLessActionsFacet: PartyB is in emergency mode");
		require(!appLayout.emergencyMode, "OracleLessActionsFacet: System is in emergency mode");
		require(!MAStorage.layout().liquidationStatus[firstQuote.partyA], "OracleLessActionsFacet: PartyA isn't solvent");
		require(!MAStorage.layout().partyBLiquidationStatus[firstQuote.partyB][firstQuote.partyA], "OracleLessActionsFacet: PartyB isn't solvent");
		require(
			AccountStorage.layout().boundPartyB[firstQuote.partyA] == firstQuote.partyB,
			"OracleLessActionsFacet: PartyB is not bounded to this partyA"
		);
		accountLayout.partyANonces[firstQuote.partyA] += 1;
		accountLayout.partyBNonces[firstQuote.partyB][firstQuote.partyA] += 1;
		currentIds = new uint256[](quoteIds.length);
		for (uint8 i = 0; i < quoteIds.length; i++) {
			uint256 quoteId = quoteIds[i];
			uint256 filledAmount = filledAmounts[i];
			uint256 openedPrice = openedPrices[i];
			Quote storage quote = QuoteStorage.layout().quotes[quoteId];
			require(quote.partyB == msg.sender, "OracleLessActionsFacet: Sender should be the partyB");
			require(firstQuote.partyA == quote.partyA, "OracleLessActionsFacet: All positions should belong to one partyA");
			currentIds[i] = LibPartyB.openPosition(quoteId, filledAmount, openedPrice);
		}
	}

	function fillCloseRequests(
		uint256[] memory quoteIds,
		uint256[] memory filledAmounts,
		uint256[] memory closedPrices
	) internal returns (QuoteStatus[] memory quoteStatuses, uint256[] memory closeIds) {
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		require(
			quoteIds.length == filledAmounts.length && quoteIds.length == closedPrices.length && quoteIds.length > 0,
			"OracleLessActionsFacet: Invalid length"
		);
		quoteStatuses = new QuoteStatus[](quoteIds.length);
		closeIds = new uint256[](quoteIds.length);
		Quote storage firstQuote = QuoteStorage.layout().quotes[quoteIds[0]];
		accountLayout.partyBNonces[firstQuote.partyB][firstQuote.partyA] += 1;
		accountLayout.partyANonces[firstQuote.partyA] += 1;
		require(!MAStorage.layout().liquidationStatus[firstQuote.partyA], "OracleLessActionsFacet: PartyA isn't solvent");
		require(!MAStorage.layout().partyBLiquidationStatus[firstQuote.partyB][firstQuote.partyA], "OracleLessActionsFacet: PartyB isn't solvent");
		require(
			AccountStorage.layout().boundPartyB[firstQuote.partyA] == firstQuote.partyB,
			"OracleLessActionsFacet: PartyB is not bounded to this partyA"
		);
		for (uint8 i = 0; i < quoteIds.length; i++) {
			uint256 quoteId = quoteIds[i];
			uint256 filledAmount = filledAmounts[i];
			uint256 closedPrice = closedPrices[i];
			Quote storage quote = QuoteStorage.layout().quotes[quoteId];
			require(quote.partyB == msg.sender, "OracleLessActionsFacet: Sender should be the partyB");
			require(firstQuote.partyA == quote.partyA, "OracleLessActionsFacet: All positions should belong to one partyA");
			LibPartyB.fillCloseRequest(quoteId, filledAmount, closedPrice);
			quoteStatuses[i] = quote.quoteStatus;
			closeIds[i] = QuoteStorage.layout().closeIds[quoteId];
		}
	}
}
