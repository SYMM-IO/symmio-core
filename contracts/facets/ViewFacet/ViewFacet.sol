// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibLockedValues.sol";
import "../../libraries/LibQuote.sol";
import "../../libraries/LibMuon.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/SymbolStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../libraries/LibLockedValues.sol";
import "../../storages/BridgeStorage.sol";
import "./IViewFacet.sol";

contract ViewFacet is IViewFacet {
	using LockedValuesOps for LockedValues;

	// Account
	function balanceOf(address user) external view returns (uint256) {
		return AccountStorage.layout().balances[user];
	}

	function partyAStats(
		address partyA
	)
		external
		view
		returns (bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
	{
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		MAStorage.Layout storage maLayout = MAStorage.layout();
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		return (
			maLayout.liquidationStatus[partyA],
			accountLayout.allocatedBalances[partyA],
			accountLayout.lockedBalances[partyA].cva,
			accountLayout.lockedBalances[partyA].lf,
			accountLayout.lockedBalances[partyA].partyAmm,
			accountLayout.lockedBalances[partyA].partyBmm,
			accountLayout.pendingLockedBalances[partyA].cva,
			accountLayout.pendingLockedBalances[partyA].lf,
			accountLayout.pendingLockedBalances[partyA].partyAmm,
			accountLayout.pendingLockedBalances[partyA].partyBmm,
			quoteLayout.partyAPositionsCount[partyA],
			quoteLayout.partyAPendingQuotes[partyA].length,
			accountLayout.partyANonces[partyA],
			quoteLayout.quoteIdsOf[partyA].length
		);
	}

	function balanceInfoOfPartyA(
		address partyA
	) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		return (
			accountLayout.allocatedBalances[partyA],
			accountLayout.lockedBalances[partyA].cva,
			accountLayout.lockedBalances[partyA].lf,
			accountLayout.lockedBalances[partyA].partyAmm,
			accountLayout.lockedBalances[partyA].partyBmm,
			accountLayout.pendingLockedBalances[partyA].cva,
			accountLayout.pendingLockedBalances[partyA].lf,
			accountLayout.pendingLockedBalances[partyA].partyAmm,
			accountLayout.pendingLockedBalances[partyA].partyBmm
		);
	}

	function balanceInfoOfPartyB(
		address partyB,
		address partyA
	) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		AccountStorage.Layout storage accountLayout = AccountStorage.layout();
		return (
			accountLayout.partyBAllocatedBalances[partyB][partyA],
			accountLayout.partyBLockedBalances[partyB][partyA].cva,
			accountLayout.partyBLockedBalances[partyB][partyA].lf,
			accountLayout.partyBLockedBalances[partyB][partyA].partyAmm,
			accountLayout.partyBLockedBalances[partyB][partyA].partyBmm,
			accountLayout.partyBPendingLockedBalances[partyB][partyA].cva,
			accountLayout.partyBPendingLockedBalances[partyB][partyA].lf,
			accountLayout.partyBPendingLockedBalances[partyB][partyA].partyAmm,
			accountLayout.partyBPendingLockedBalances[partyB][partyA].partyBmm
		);
	}

	function allocatedBalanceOfPartyA(address partyA) external view returns (uint256) {
		return AccountStorage.layout().allocatedBalances[partyA];
	}

	function allocatedBalanceOfPartyB(address partyB, address partyA) external view returns (uint256) {
		return AccountStorage.layout().partyBAllocatedBalances[partyB][partyA];
	}

	function allocatedBalanceOfPartyBs(address partyA, address[] memory partyBs) external view returns (uint256[] memory) {
		uint256[] memory allocatedBalances = new uint256[](partyBs.length);
		for (uint256 i = 0; i < partyBs.length; i++) {
			allocatedBalances[i] = AccountStorage.layout().partyBAllocatedBalances[partyBs[i]][partyA];
		}
		return allocatedBalances;
	}

	function withdrawCooldownOf(address user) external view returns (uint256) {
		return AccountStorage.layout().withdrawCooldown[user];
	}

	function nonceOfPartyA(address partyA) external view returns (uint256) {
		return AccountStorage.layout().partyANonces[partyA];
	}

	function nonceOfPartyB(address partyB, address partyA) external view returns (uint256) {
		return AccountStorage.layout().partyBNonces[partyB][partyA];
	}

	function isSuspended(address user) external view returns (bool) {
		return AccountStorage.layout().suspendedAddresses[user];
	}

	function getLiquidatedStateOfPartyA(address partyA) external view returns (LiquidationDetail memory) {
		return AccountStorage.layout().liquidationDetails[partyA];
	}

	function getSettlementStates(address partyA, address[] memory partyBs) external view returns (SettlementState[] memory) {
		SettlementState[] memory states = new SettlementState[](partyBs.length);
		for (uint256 i = 0; i < partyBs.length; i++) {
			states[i] = AccountStorage.layout().settlementStates[partyA][partyBs[i]];
		}
		return states;
	}

	///////////////////////////////////////////

	// Symbols
	function getSymbol(uint256 symbolId) external view returns (Symbol memory) {
		return SymbolStorage.layout().symbols[symbolId];
	}

	function getSymbols(uint256 start, uint256 size) external view returns (Symbol[] memory) {
		SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
		if (symbolLayout.lastId < start + size) {
			size = symbolLayout.lastId - start;
		}
		Symbol[] memory symbols = new Symbol[](size);
		for (uint256 i = start; i < start + size; i++) {
			symbols[i - start] = symbolLayout.symbols[i + 1];
		}
		return symbols;
	}

	function symbolsByQuoteId(uint256[] memory quoteIds) external view returns (Symbol[] memory) {
		Symbol[] memory symbols = new Symbol[](quoteIds.length);
		for (uint256 i = 0; i < quoteIds.length; i++) {
			symbols[i] = SymbolStorage.layout().symbols[QuoteStorage.layout().quotes[quoteIds[i]].symbolId];
		}
		return symbols;
	}

	function symbolNameByQuoteId(uint256[] memory quoteIds) external view returns (string[] memory) {
		string[] memory symbols = new string[](quoteIds.length);
		for (uint256 i = 0; i < quoteIds.length; i++) {
			symbols[i] = SymbolStorage.layout().symbols[QuoteStorage.layout().quotes[quoteIds[i]].symbolId].name;
		}
		return symbols;
	}

	function symbolNameById(uint256[] memory symbolIds) external view returns (string[] memory) {
		string[] memory symbols = new string[](symbolIds.length);
		for (uint256 i = 0; i < symbolIds.length; i++) {
			symbols[i] = SymbolStorage.layout().symbols[symbolIds[i]].name;
		}
		return symbols;
	}

	////////////////////////////////////

	// Quotes
	function getQuote(uint256 quoteId) external view returns (Quote memory) {
		return QuoteStorage.layout().quotes[quoteId];
	}

	function getQuotesByParent(uint256 quoteId, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		Quote[] memory quotes = new Quote[](size);
		Quote memory quote = quoteLayout.quotes[quoteId];
		quotes[0] = quote;
		for (uint256 i = 1; i < size; i++) {
			if (quote.parentId == 0) {
				break;
			}
			quote = quoteLayout.quotes[quote.parentId];
			quotes[i] = quote;
		}
		return quotes;
	}

	function quoteIdsOf(address partyA, uint256 start, uint256 size) external view returns (uint256[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.quoteIdsOf[partyA].length < start + size) {
			size = quoteLayout.quoteIdsOf[partyA].length - start;
		}
		uint256[] memory quoteIds = new uint256[](size);
		for (uint256 i = start; i < start + size; i++) {
			quoteIds[i - start] = quoteLayout.quoteIdsOf[partyA][i];
		}
		return quoteIds;
	}

	function getQuotes(address partyA, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.quoteIdsOf[partyA].length < start + size) {
			size = quoteLayout.quoteIdsOf[partyA].length - start;
		}
		Quote[] memory quotes = new Quote[](size);
		for (uint256 i = start; i < start + size; i++) {
			quotes[i - start] = quoteLayout.quotes[quoteLayout.quoteIdsOf[partyA][i]];
		}
		return quotes;
	}

	function quotesLength(address user) external view returns (uint256) {
		return QuoteStorage.layout().quoteIdsOf[user].length;
	}

	function partyAPositionsCount(address partyA) external view returns (uint256) {
		return QuoteStorage.layout().partyAPositionsCount[partyA];
	}

	function getPartyAOpenPositions(address partyA, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.partyAOpenPositions[partyA].length < start + size) {
			size = quoteLayout.partyAOpenPositions[partyA].length - start;
		}
		Quote[] memory quotes = new Quote[](size);
		for (uint256 i = start; i < start + size; i++) {
			quotes[i - start] = quoteLayout.quotes[quoteLayout.partyAOpenPositions[partyA][i]];
		}
		return quotes;
	}

	function getPartyBOpenPositions(address partyB, address partyA, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.partyBOpenPositions[partyB][partyA].length < start + size) {
			size = quoteLayout.partyBOpenPositions[partyB][partyA].length - start;
		}
		Quote[] memory quotes = new Quote[](size);
		for (uint256 i = start; i < start + size; i++) {
			quotes[i - start] = quoteLayout.quotes[quoteLayout.partyBOpenPositions[partyB][partyA][i]];
		}
		return quotes;
	}

	function getPositionsFilteredByPartyB(address partyB, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		Quote[] memory quotes = new Quote[](size);
		uint j = 0;
		for (uint256 i = start; i < start + size; i++) {
			Quote memory quote = quoteLayout.quotes[i];
			if (quote.partyB == partyB) {
				quotes[j] = quote;
				j += 1;
			}
		}
		return quotes;
	}

	function getOpenPositionsFilteredByPartyB(address partyB, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		Quote[] memory quotes = new Quote[](size);
		uint j = 0;
		for (uint256 i = start; i < start + size; i++) {
			Quote memory quote = quoteLayout.quotes[i];
			if (
				quote.partyB == partyB &&
				(quote.quoteStatus == QuoteStatus.OPENED ||
					quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
					quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING)
			) {
				quotes[j] = quote;
				j += 1;
			}
		}
		return quotes;
	}

	function getActivePositionsFilteredByPartyB(address partyB, uint256 start, uint256 size) external view returns (Quote[] memory) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		Quote[] memory quotes = new Quote[](size);
		uint j = 0;
		for (uint256 i = start; i < start + size; i++) {
			Quote memory quote = quoteLayout.quotes[i];
			if (
				quote.partyB == partyB &&
				quote.quoteStatus != QuoteStatus.CANCELED &&
				quote.quoteStatus != QuoteStatus.CLOSED &&
				quote.quoteStatus != QuoteStatus.EXPIRED &&
				quote.quoteStatus != QuoteStatus.LIQUIDATED
			) {
				quotes[j] = quote;
				j += 1;
			}
		}
		return quotes;
	}

	function partyBPositionsCount(address partyB, address partyA) external view returns (uint256) {
		return QuoteStorage.layout().partyBPositionsCount[partyB][partyA];
	}

	function getPartyAPendingQuotes(address partyA) external view returns (uint256[] memory) {
		return QuoteStorage.layout().partyAPendingQuotes[partyA];
	}

	function getPartyBPendingQuotes(address partyB, address partyA) external view returns (uint256[] memory) {
		return QuoteStorage.layout().partyBPendingQuotes[partyB][partyA];
	}

	/////////////////////////////////////

	// Role
	function hasRole(address user, bytes32 role) external view returns (bool) {
		return GlobalAppStorage.layout().hasRole[user][role];
	}

	function getRoleHash(string memory str) external pure returns (bytes32) {
		return keccak256(abi.encodePacked(str));
	}

	//////////////////////////////////////

	// MA
	function getCollateral() external view returns (address) {
		return GlobalAppStorage.layout().collateral;
	}

	function getFeeCollector() external view returns (address) {
		return GlobalAppStorage.layout().feeCollector;
	}

	function isPartyALiquidated(address partyA) external view returns (bool) {
		return MAStorage.layout().liquidationStatus[partyA];
	}

	function isPartyBLiquidated(address partyB, address partyA) external view returns (bool) {
		return MAStorage.layout().partyBLiquidationStatus[partyB][partyA];
	}

	function isPartyB(address user) external view returns (bool) {
		return MAStorage.layout().partyBStatus[user];
	}

	function pendingQuotesValidLength() external view returns (uint256) {
		return MAStorage.layout().pendingQuotesValidLength;
	}

	function forceCloseGapRatio() external view returns (uint256) {
		return MAStorage.layout().forceCloseGapRatio;
	}

	function forceClosePricePenalty() external view returns (uint256) {
		return MAStorage.layout().forceClosePricePenalty;
	}

	function forceCloseMinSigPeriod() external view returns (uint256) {
		return MAStorage.layout().forceCloseMinSigPeriod;
	}

	function liquidatorShare() external view returns (uint256) {
		return MAStorage.layout().liquidatorShare;
	}

	function liquidationTimeout() external view returns (uint256) {
		return MAStorage.layout().liquidationTimeout;
	}

	function partyBLiquidationTimestamp(address partyB, address partyA) external view returns (uint256) {
		return MAStorage.layout().partyBLiquidationTimestamp[partyB][partyA];
	}

	function coolDownsOfMA() external view returns (uint256, uint256, uint256, uint256, uint256) {
		return (
			MAStorage.layout().deallocateCooldown,
			MAStorage.layout().forceCancelCooldown,
			MAStorage.layout().forceCancelCloseCooldown,
			MAStorage.layout().forceCloseFirstCooldown,
			MAStorage.layout().forceCloseSecondCooldown
		);
	}

	///////////////////////////////////////////

	function getMuonConfig() external view returns (uint256 upnlValidTime, uint256 priceValidTime, uint256 priceQuantityValidTime) {
		upnlValidTime = MuonStorage.layout().upnlValidTime;
		priceValidTime = MuonStorage.layout().priceValidTime;
		priceQuantityValidTime = MuonStorage.layout().priceQuantityValidTime;
	}

	function getMuonIds() external view returns (uint256 muonAppId, PublicKey memory muonPublicKey, address validGateway) {
		muonAppId = MuonStorage.layout().muonAppId;
		muonPublicKey = MuonStorage.layout().muonPublicKey;
		validGateway = MuonStorage.layout().validGateway;
	}

	function pauseState()
		external
		view
		returns (
			bool globalPaused,
			bool liquidationPaused,
			bool accountingPaused,
			bool partyBActionsPaused,
			bool partyAActionsPaused,
			bool emergencyMode
		)
	{
		GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
		return (
			appLayout.globalPaused,
			appLayout.liquidationPaused,
			appLayout.accountingPaused,
			appLayout.partyBActionsPaused,
			appLayout.partyAActionsPaused,
			appLayout.emergencyMode
		);
	}

	function getPartyBEmergencyStatus(address partyB) external view returns (bool isEmergency) {
		return GlobalAppStorage.layout().partyBEmergencyStatus[partyB];
	}

	function getBalanceLimitPerUser() external view returns (uint256) {
		return GlobalAppStorage.layout().balanceLimitPerUser;
	}

	function verifyMuonTSSAndGateway(bytes32 hash, SchnorrSign memory sign, bytes memory gatewaySignature) external view {
		LibMuon.verifyTSSAndGateway(hash, sign, gatewaySignature);
	}

	function getNextQuoteId() external view returns (uint256) {
		return QuoteStorage.layout().lastId;
	}

	function getBridgeTransaction(uint256 transactionId) external view returns (BridgeTransaction memory) {
		return BridgeStorage.layout().bridgeTransactions[transactionId];
	}

	function getNextBridgeTransactionId() external view returns (uint256) {
		return QuoteStorage.layout().lastId;
	}

	function getQuoteCloseId(uint256 quoteId) external view returns (uint256) {
		return QuoteStorage.layout().closeIds[quoteId];
	}

	function countPartyBOpenPositionsWithPartyA(address partyB, address partyA) external view returns (uint256 count) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		
		count = quoteLayout.partyBOpenPositions[partyB][partyA].length;
	}

	function getPartyBOpenPositionsWithPartyA(address partyB, address partyA, uint256 start, uint256 size) external view returns (Quote[] memory quotes) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.partyBOpenPositions[partyB][partyA].length < start + size) {
			size = quoteLayout.partyBOpenPositions[partyB][partyA].length - start;
		}
		quotes = new Quote[](size);
		for (uint256 i = start; i < start + size; i++) {
			quotes[i - start] = quoteLayout.quotes[quoteLayout.partyBOpenPositions[partyB][partyA][i]];
		}
	}
	
	function countPartyBPendingQuotesWithPartyA(address partyB, address partyA) external view returns (uint256 count) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		
		count = quoteLayout.partyBPendingQuotes[partyB][partyA].length;
	}

	function getPartyBPendingQuotesWithPartyA(address partyB, address partyA, uint256 start, uint256 size) external view returns (Quote[] memory quotes) {
		QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
		if (quoteLayout.partyBPendingQuotes[partyB][partyA].length < start + size) {
			size = quoteLayout.partyBPendingQuotes[partyB][partyA].length - start;
		}
		quotes = new Quote[](size);
		for (uint256 i = start; i < start + size; i++) {
			quotes[i - start] = quoteLayout.quotes[quoteLayout.partyBPendingQuotes[partyB][partyA][i]];
		}
	}

	function getPositionsFilteredByPartyB(
		address partyB, 
		uint256 cursor, 
		uint256 maxPageSize, 
		uint256 gasNeededForReturn, 
		uint256 gasCostForQuoteMemLoad
	) external view returns (Quote[] memory quotes, uint256 retCursor) {
		QuoteStorage.Layout storage qL = QuoteStorage.layout();
		uint256 end = qL.lastId;
		retCursor = cursor;

		uint256[] memory cache = new uint256[](maxPageSize);
		uint256 cacheSize = 0;
		do {
			// Filter by partyB
			if (qL.quotes[retCursor].partyB == partyB) {
				cache[cacheSize] = retCursor;
				++cacheSize;
				if (cacheSize == maxPageSize) {
					++retCursor;
					break;
				}
			}
			++retCursor;
		} while (retCursor < end && gasleft() > gasNeededForReturn + gasCostForQuoteMemLoad * cacheSize);

		if (retCursor == end) {
			retCursor = type(uint256).max;
		}

		quotes = new Quote[](cacheSize);
		for (uint256 i = 0; i < cacheSize; ++i) {
			quotes[i] = qL.quotes[cache[i]];
		}
	}

	function getPositionsFilteredByStatus(
		uint256 statusMask, 
		uint256 cursor, 
		uint256 maxPageSize, 
		uint256 gasNeededForReturn, 
		uint256 gasCostForQuoteMemLoad
	) external view returns (Quote[] memory quotes, uint256 retCursor) {
		QuoteStorage.Layout storage qL = QuoteStorage.layout();
		uint256 end = qL.lastId;
		retCursor = cursor;

		uint256[] memory cache = new uint256[](maxPageSize);
		uint256 cacheSize = 0;
		do {
			// Filter by statusMask
			if (((1 << uint256(qL.quotes[retCursor].quoteStatus)) & statusMask) > 0) {
				cache[cacheSize] = retCursor;
				++cacheSize;
				if (cacheSize == maxPageSize) {
					++retCursor;
					break;
				}
			}
			++retCursor;
		} while (retCursor < end && gasleft() > gasNeededForReturn + gasCostForQuoteMemLoad * cacheSize);

		if (retCursor == end) {
			retCursor = type(uint256).max;
		}

		quotes = new Quote[](cacheSize);
		for (uint256 i = 0; i < cacheSize; ++i) {
			quotes[i] = qL.quotes[cache[i]];
		}
	}

	function getPositionsFilteredByPartyBAndStatus(
		address partyB,
		uint256 statusMask, 
		uint256 cursor, 
		uint256 maxPageSize, 
		uint256 gasNeededForReturn, 
		uint256 gasCostForQuoteMemLoad
	) external view returns (Quote[] memory quotes, uint256 retCursor) {
		QuoteStorage.Layout storage qL = QuoteStorage.layout();
		uint256 end = qL.lastId;
		retCursor = cursor;

		uint256[] memory cache = new uint256[](maxPageSize);
		uint256 cacheSize = 0;
		do {
			Quote storage q = qL.quotes[retCursor];
			// Filter by partyB and statusMask
			if (q.partyB == partyB && ((1 << uint256(q.quoteStatus)) & statusMask) > 0) {
				cache[cacheSize] = retCursor;
				++cacheSize;
				if (cacheSize == maxPageSize) {
					++retCursor;
					break;
				}
			}
			++retCursor;
		} while (retCursor < end && gasleft() > gasNeededForReturn + gasCostForQuoteMemLoad * cacheSize);

		if (retCursor == end) {
			retCursor = type(uint256).max;
		}

		quotes = new Quote[](cacheSize);
		for (uint256 i = 0; i < cacheSize; ++i) {
			quotes[i] = qL.quotes[cache[i]];
		}
	}
}