// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

/**
 * @title ICampaignRegistry
 * @dev Interface for the Campaign Registry
 * @notice Defines the structure and functions for managing advertising campaigns
 */
interface ICampaignRegistry {
    // ============ Structs ============

    /**
     * @dev Budget information for a campaign
     * @param amount The budget amount
     * @param tokenAddress The token address for the budget (e.g., USDC, ETH)
     */
    struct Budget {
        uint256 amount;
        address tokenAddress;
    }

    /**
     * @dev Campaign information
     * @param campaignId Unique identifier for the campaign
     * @param advertiserId ID of the advertiser who created the campaign
     * @param budget Budget allocation for the campaign
     * @param startTime Timestamp when the campaign becomes active
     * @param expiryTime Timestamp when the campaign expires
     * @param spec Encoded campaign specification (title, description, rules, etc.)
     */
    struct Campaign {
        uint256 campaignId;
        uint256 advertiserId;
        Budget budget;
        uint256 startTime;
        uint256 expiryTime;
        bytes spec;
    }

    // ============ Events ============

    /**
     * @dev Emitted when a new campaign is created
     * @param campaignId The ID of the created campaign
     * @param advertiserId The ID of the advertiser
     * @param budgetAmount The budget amount
     * @param budgetTokenAddress The token address for the budget
     * @param startTime Campaign start time
     * @param expiryTime Campaign expiry time
     */
    event CampaignCreated(
        uint256 indexed campaignId,
        uint256 indexed advertiserId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 startTime,
        uint256 expiryTime
    );

    /**
     * @dev Emitted when a campaign is updated
     * @param campaignId The ID of the updated campaign
     * @param budgetAmount The new budget amount
     * @param budgetTokenAddress The new token address
     * @param startTime New start time
     * @param expiryTime New expiry time
     */
    event CampaignUpdated(
        uint256 indexed campaignId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 startTime,
        uint256 expiryTime
    );

    // ============ Errors ============

    error UnauthorizedCaller();
    error InvalidBudgetAmount();
    error InvalidTokenAddress();
    error InvalidTimeRange();
    error CampaignAlreadyExpired();
    error CampaignNotFound();

    // ============ Write Functions ============

    /**
     * @dev Creates a new advertising campaign
     * @param advertiserId ID of the advertiser creating the campaign
     * @param budgetAmount Budget amount for the campaign
     * @param budgetTokenAddress Token address for the budget
     * @param startTime Timestamp when campaign starts
     * @param expiryTime Timestamp when campaign expires
     * @param spec Encoded campaign specification (title, description, rules, etc.)
     * @return campaignId The ID of the created campaign
     */
    function createCampaign(
        uint256 advertiserId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (uint256 campaignId);

    /**
     * @dev Updates an existing campaign
     * @param campaignId ID of the campaign to update
     * @param budgetAmount New budget amount
     * @param budgetTokenAddress New token address
     * @param startTime New start time
     * @param expiryTime New expiry time
     * @param spec New campaign specification (title, description, rules, etc.)
     * @return success True if update was successful
     */
    function updateCampaign(
        uint256 campaignId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (bool success);

    // ============ Read Functions ============

    /**
     * @dev Retrieves campaign information by ID
     * @param campaignId The campaign ID to query
     * @return campaign The campaign information
     */
    function getCampaign(uint256 campaignId) external view returns (Campaign memory campaign);

    /**
     * @dev Retrieves all campaign IDs for a specific advertiser
     * @param advertiserId The advertiser ID to query
     * @return campaignIds Array of campaign IDs
     */
    function getCampaignsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory campaignIds);

    /**
     * @dev Returns the total number of campaigns created
     * @return count The total campaign count
     */
    function getCampaignCount() external view returns (uint256 count);

    /**
     * @dev Checks if a campaign exists
     * @param campaignId The campaign ID to check
     * @return exists True if the campaign exists
     */
    function campaignExists(uint256 campaignId) external view returns (bool exists);

    /**
     * @dev Checks if a campaign is currently active (within start and expiry time)
     * @param campaignId The campaign ID to check
     * @return active True if the campaign is active
     */
    function isCampaignActive(uint256 campaignId) external view returns (bool active);
}
