// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IAccountFacet.sol";
import "./AccountFacetImpl.sol";
import "../../storages/GlobalAppStorage.sol";

/// @title Manage Deposits and Allocated Amounts
contract AccountFacet is Accessibility, Pausable, IAccountFacet {
	//Party A

	/// @notice Allows either Party A or Party B to deposit collateral.
	/// @dev This function can be utilized by both parties to deposit collateral into the system.
	/// @param amount The collateral amount of collateral to be deposited, specified in decimal units.
	function deposit(uint256 amount) external whenNotAccountingPaused {
		AccountFacetImpl.deposit(msg.sender, amount);
		emit Deposit(msg.sender, msg.sender, amount);
	}

	function depositFor(address user, uint256 amount) external whenNotAccountingPaused {
		AccountFacetImpl.deposit(user, amount);
		emit Deposit(msg.sender, user, amount);
	}

	function withdraw(uint256 amount) external whenNotAccountingPaused notSuspended(msg.sender) {
		AccountFacetImpl.withdraw(msg.sender, amount);
		emit Withdraw(msg.sender, msg.sender, amount);
	}

	function withdrawTo(address user, uint256 amount) external whenNotAccountingPaused notSuspended(msg.sender) {
		AccountFacetImpl.withdraw(user, amount);
		emit Withdraw(msg.sender, user, amount);
	}

	function allocate(uint256 amount) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
		AccountFacetImpl.allocate(amount);
		emit AllocatePartyA(msg.sender, amount);
	}

	function depositAndAllocate(uint256 amount) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
		AccountFacetImpl.deposit(msg.sender, amount);
		uint256 amountWith18Decimals = (amount * 1e18) / (10 ** IERC20Metadata(GlobalAppStorage.layout().collateral).decimals());
		AccountFacetImpl.allocate(amountWith18Decimals);
		emit Deposit(msg.sender, msg.sender, amount);
		emit AllocatePartyA(msg.sender, amountWith18Decimals);
	}

	function deallocate(uint256 amount, SingleUpnlSig memory upnlSig) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
		AccountFacetImpl.deallocate(amount, upnlSig);
		emit DeallocatePartyA(msg.sender, amount);
	}

	/// @notice Transfers the sender's deposite balance to the user allocated balance.
	/// @dev allocatedPerUser is checked
	/// @dev The sender and the recipient user cannot be partyB.
	/// @param user The address of the user to whom the amount is allocated.
	/// @param amount The amount to transfer and allocate.
	function internalTransfer(address user, uint256 amount) external whenNotInternalTransferPaused notPartyB userNotPartyB(user) notSuspended(msg.sender){
		AccountFacetImpl.internalTransfer(user, amount);
		emit InternalTransfer(msg.sender,user,amount); 
	}

	// PartyB
	function allocateForPartyB(uint256 amount, address partyA) public whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) onlyPartyB {
		AccountFacetImpl.allocateForPartyB(amount, partyA);
		emit AllocateForPartyB(msg.sender, partyA, amount);
	}

	function deallocateForPartyB(
		uint256 amount,
		address partyA,
		SingleUpnlSig memory upnlSig
	) external whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) notLiquidatedPartyA(partyA) onlyPartyB {
		AccountFacetImpl.deallocateForPartyB(amount, partyA, upnlSig);
		emit DeallocateForPartyB(msg.sender, partyA, amount);
	}

	function transferAllocation(uint256 amount, address origin, address recipient, SingleUpnlSig memory upnlSig) external whenNotPartyBActionsPaused {
		AccountFacetImpl.transferAllocation(amount, origin, recipient, upnlSig);
		emit TransferAllocation(amount, origin, recipient);
	}
}
