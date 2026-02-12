// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

import "./interfaces/ICampaignRegistry.sol";
import "./interfaces/IIdentityRegistry.sol";

/**
 * @title CampaignRegistry
 * @dev Registry for managing advertising campaigns
 * @notice Allows advertisers to create and manage ad campaigns with budget and timing controls
 * @author APEX Network
 */
contract CampaignRegistry is ICampaignRegistry {
    // ============ State Variables ============

    /// @dev Reference to the IdentityRegistry for advertiser validation
    IIdentityRegistry public immutable identityRegistry;

    /// @dev Counter for campaign IDs
    uint256 private _campaignIdCounter;

    /// @dev Mapping from campaign ID to campaign info
    mapping(uint256 => Campaign) private _campaigns;

    /// @dev Mapping from advertiser ID to their campaign IDs
    mapping(uint256 => uint256[]) private _advertiserCampaigns;

    // ============ Constructor ============

    /**
     * @dev Constructor sets the identity registry reference
     * @param _identityRegistry Address of the IdentityRegistry contract
     */
    constructor(address _identityRegistry) {
        identityRegistry = IIdentityRegistry(_identityRegistry);
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
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (uint256 campaignId) {
        // Validate advertiser exists and caller is authorized
        IIdentityRegistry.AgentInfo memory advertiserInfo = identityRegistry.getAgent(advertiserId);
        if (advertiserInfo.agentId == 0) {
            revert AdvertiserNotFound();
        }
        if (advertiserInfo.agentAddress != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Validate inputs
        if (budgetAmount == 0) {
            revert InvalidBudgetAmount();
        }
        if (budgetTokenAddress == address(0)) {
            revert InvalidTokenAddress();
        }
        if (startTime >= expiryTime) {
            revert InvalidTimeRange();
        }
        if (expiryTime <= block.timestamp) {
            revert CampaignAlreadyExpired();
        }

        // Assign new campaign ID
        campaignId = _campaignIdCounter++;

        // Create budget struct
        Budget memory budget = Budget({
            amount: budgetAmount,
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

        emit CampaignCreated(campaignId, advertiserId, budgetAmount, budgetTokenAddress, startTime, expiryTime);
    }

    /**
     * @inheritdoc ICampaignRegistry
     */
    function updateCampaign(
        uint256 campaignId,
        uint256 budgetAmount,
        address budgetTokenAddress,
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
        IIdentityRegistry.AgentInfo memory advertiserInfo = identityRegistry.getAgent(campaign.advertiserId);
        if (advertiserInfo.agentAddress != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Validate inputs
        if (budgetAmount == 0) {
            revert InvalidBudgetAmount();
        }
        if (budgetTokenAddress == address(0)) {
            revert InvalidTokenAddress();
        }
        if (startTime >= expiryTime) {
            revert InvalidTimeRange();
        }
        if (expiryTime <= block.timestamp) {
            revert CampaignAlreadyExpired();
        }

        // Update campaign
        campaign.budget.amount = budgetAmount;
        campaign.budget.tokenAddress = budgetTokenAddress;
        campaign.startTime = startTime;
        campaign.expiryTime = expiryTime;
        campaign.spec = spec;

        emit CampaignUpdated(campaignId, budgetAmount, budgetTokenAddress, startTime, expiryTime);
        return true;
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

        return block.timestamp >= campaign.startTime && block.timestamp < campaign.expiryTime;
    }
}
