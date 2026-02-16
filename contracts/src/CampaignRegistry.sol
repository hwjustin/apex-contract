// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

import "./interfaces/ICampaignRegistry.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title CampaignRegistry
 * @dev Registry for managing advertising campaigns with budget escrow and CPA payments
 * @notice Allows advertisers to create campaigns with escrowed budgets, validators to trigger
 *         CPA payments to publishers, and advertisers to reclaim unspent funds after expiry
 * @author APEX Network
 */
contract CampaignRegistry is ICampaignRegistry {
    // ============ State Variables ============

    /// @dev Reference to the EIP-8004 Identity Registry (ERC-721)
    IERC721 public immutable identityRegistry;

    /// @dev Counter for campaign IDs
    uint256 private _campaignIdCounter;

    /// @dev Mapping from campaign ID to campaign info
    mapping(uint256 => Campaign) private _campaigns;

    /// @dev Mapping from advertiser ID to their campaign IDs
    mapping(uint256 => uint256[]) private _advertiserCampaigns;

    /// @dev Mapping from action hash to whether it has been processed
    mapping(bytes32 => bool) private _processedActions;

    // ============ Constructor ============

    /**
     * @dev Constructor sets the identity registry reference
     * @param _identityRegistry Address of the IdentityRegistry contract
     */
    constructor(address _identityRegistry) {
        identityRegistry = IERC721(_identityRegistry);
        // Start campaign IDs from 1 (0 is reserved for "not found")
        _campaignIdCounter = 1;
    }

    // ============ Write Functions ============

    /**
     * @inheritdoc ICampaignRegistry
     */
    function createCampaign(
        uint256 advertiserId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (uint256 campaignId) {
        // Validate advertiser exists and caller is authorized
        address advertiserOwner = identityRegistry.ownerOf(advertiserId); // reverts if agent doesn't exist
        if (advertiserOwner != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Validate inputs
        if (budgetAmount == 0) {
            revert InvalidBudgetAmount();
        }
        if (budgetTokenAddress == address(0)) {
            revert InvalidTokenAddress();
        }
        if (cpaAmount == 0 || cpaAmount > budgetAmount) {
            revert InvalidCpaAmount();
        }
        if (startTime >= expiryTime) {
            revert InvalidTimeRange();
        }
        if (expiryTime <= block.timestamp) {
            revert CampaignAlreadyExpired();
        }

        // Escrow budget tokens from advertiser
        bool success = IERC20(budgetTokenAddress).transferFrom(msg.sender, address(this), budgetAmount);
        if (!success) {
            revert TransferFailed();
        }

        // Assign new campaign ID
        campaignId = _campaignIdCounter++;

        // Create budget struct
        Budget memory budget = Budget({
            amount: budgetAmount,
            spent: 0,
            cpaAmount: cpaAmount,
            tokenAddress: budgetTokenAddress
        });

        // Store campaign info
        _campaigns[campaignId] = Campaign({
            campaignId: campaignId,
            advertiserId: advertiserId,
            budget: budget,
            startTime: startTime,
            expiryTime: expiryTime,
            spec: spec
        });

        // Track advertiser's campaigns
        _advertiserCampaigns[advertiserId].push(campaignId);

        emit CampaignCreated(campaignId, advertiserId, budgetAmount, budgetTokenAddress, cpaAmount, startTime, expiryTime);
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function updateCampaign(
        uint256 campaignId,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (bool success) {
        // Validate campaign exists
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }

        // Validate caller is authorized to update this campaign
        address advertiserOwner = identityRegistry.ownerOf(campaign.advertiserId); // reverts if agent doesn't exist
        if (advertiserOwner != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Validate CPA against remaining budget
        uint256 remaining = campaign.budget.amount - campaign.budget.spent;
        if (cpaAmount == 0 || cpaAmount > remaining) {
            revert InvalidCpaAmount();
        }
        if (startTime >= expiryTime) {
            revert InvalidTimeRange();
        }
        if (expiryTime <= block.timestamp) {
            revert CampaignAlreadyExpired();
        }

        // Update campaign (budget amount and token are immutable)
        campaign.budget.cpaAmount = cpaAmount;
        campaign.startTime = startTime;
        campaign.expiryTime = expiryTime;
        campaign.spec = spec;

        emit CampaignUpdated(campaignId, cpaAmount, startTime, expiryTime);
        return true;
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function processAction(
        uint256 campaignId,
        uint256 publisherId,
        uint256 validatorId,
        bytes32 actionHash
    ) external {
        // Validate campaign exists
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }

        // Validate campaign is active (time window)
        if (block.timestamp < campaign.startTime || block.timestamp >= campaign.expiryTime) {
            revert CampaignNotActive();
        }

        // Check for duplicate action
        if (_processedActions[actionHash]) {
            revert ActionAlreadyProcessed();
        }

        // Check remaining budget
        uint256 remaining = campaign.budget.amount - campaign.budget.spent;
        uint256 cpa = campaign.budget.cpaAmount;
        if (remaining < cpa) {
            revert InsufficientBudget();
        }

        // Verify caller is the validator owner
        address validatorOwner = identityRegistry.ownerOf(validatorId); // reverts if doesn't exist
        if (validatorOwner != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Resolve publisher owner
        address publisherOwner = identityRegistry.ownerOf(publisherId); // reverts if doesn't exist

        // Effects before interactions (checks-effects-interactions)
        _processedActions[actionHash] = true;
        campaign.budget.spent += cpa;

        // Transfer CPA payment to publisher owner
        bool success = IERC20(campaign.budget.tokenAddress).transfer(publisherOwner, cpa);
        if (!success) {
            revert TransferFailed();
        }

        emit ActionProcessed(campaignId, publisherId, validatorId, cpa, actionHash);
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function withdrawRemainingBudget(uint256 campaignId) external returns (uint256 amountWithdrawn) {
        // Validate campaign exists
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }

        // Only advertiser owner can withdraw
        address advertiserOwner = identityRegistry.ownerOf(campaign.advertiserId);
        if (advertiserOwner != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Campaign must be expired
        if (block.timestamp < campaign.expiryTime) {
            revert CampaignStillActive();
        }

        // Calculate remaining budget
        amountWithdrawn = campaign.budget.amount - campaign.budget.spent;
        if (amountWithdrawn == 0) {
            revert InsufficientBudget();
        }

        // Zero out before transfer (checks-effects-interactions)
        campaign.budget.spent = campaign.budget.amount;

        // Transfer remaining tokens to advertiser owner
        bool success = IERC20(campaign.budget.tokenAddress).transfer(advertiserOwner, amountWithdrawn);
        if (!success) {
            revert TransferFailed();
        }

        emit BudgetWithdrawn(campaignId, campaign.advertiserId, amountWithdrawn);
    }

    // ============ Read Functions ============

    /**
     * @inheritdoc ICampaignRegistry
     */
    function getCampaign(uint256 campaignId) external view returns (Campaign memory campaign) {
        campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function getCampaignsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory campaignIds) {
        return _advertiserCampaigns[advertiserId];
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function getCampaignCount() external view returns (uint256 count) {
        return _campaignIdCounter - 1;
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function campaignExists(uint256 campaignId) external view returns (bool exists) {
        return _campaigns[campaignId].campaignId != 0;
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function isCampaignActive(uint256 campaignId) external view returns (bool active) {
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }

        uint256 remaining = campaign.budget.amount - campaign.budget.spent;
        return block.timestamp >= campaign.startTime
            && block.timestamp < campaign.expiryTime
            && remaining >= campaign.budget.cpaAmount;
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function getCampaignRemainingBudget(uint256 campaignId) external view returns (uint256 remaining) {
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.campaignId == 0) {
            revert CampaignNotFound();
        }
        return campaign.budget.amount - campaign.budget.spent;
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function isActionProcessed(bytes32 actionHash) external view returns (bool processed) {
        return _processedActions[actionHash];
    }
}
