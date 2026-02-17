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
     * @param amount The total escrowed budget amount
     * @param spent Cumulative payouts made from this budget
     * @param cpaAmount Payment per validated action
     * @param tokenAddress The token address for the budget (e.g., USDC)
     */
    struct Budget {
        uint256 amount;
        uint256 spent;
        uint256 cpaAmount;
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
     */
    event CampaignCreated(
        uint256 indexed campaignId,
        uint256 indexed advertiserId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime
    );

    /**
     * @dev Emitted when a campaign is updated
     */
    event CampaignUpdated(
        uint256 indexed campaignId,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime
    );

    /**
     * @dev Emitted when a CPA action is processed and payment made
     */
    event ActionProcessed(
        uint256 indexed campaignId,
        uint256 indexed publisherId,
        uint256 validatorId,
        uint256 paymentAmount,
        bytes32 actionHash
    );

    /**
     * @dev Emitted when an advertiser withdraws remaining budget after campaign expiry
     */
    event BudgetWithdrawn(
        uint256 indexed campaignId,
        uint256 indexed advertiserId,
        uint256 amountWithdrawn
    );

    // ============ Errors ============

    error UnauthorizedCaller();
    error InvalidBudgetAmount();
    error InvalidTokenAddress();
    error InvalidTimeRange();
    error CampaignAlreadyExpired();
    error CampaignNotFound();
    error InsufficientBudget();
    error CampaignNotActive();
    error CampaignStillActive();
    error InvalidCpaAmount();
    error ActionAlreadyProcessed();
    error TransferFailed();

    // ============ Write Functions ============

    /**
     * @dev Creates a new advertising campaign with escrowed budget
     * @param advertiserId ID of the advertiser creating the campaign
     * @param budgetAmount Budget amount to escrow
     * @param budgetTokenAddress Token address for the budget
     * @param cpaAmount Payment per validated action
     * @param startTime Timestamp when campaign starts
     * @param expiryTime Timestamp when campaign expires
     * @param spec Encoded campaign specification (title, description, rules, etc.)
     * @return campaignId The ID of the created campaign
     */
    function createCampaign(
        uint256 advertiserId,
        uint256 budgetAmount,
        address budgetTokenAddress,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (uint256 campaignId);

    /**
     * @dev Updates an existing campaign (cannot change escrowed amount or token)
     * @param campaignId ID of the campaign to update
     * @param cpaAmount New CPA amount
     * @param startTime New start time
     * @param expiryTime New expiry time
     * @param spec New campaign specification
     * @return success True if update was successful
     */
    function updateCampaign(
        uint256 campaignId,
        uint256 cpaAmount,
        uint256 startTime,
        uint256 expiryTime,
        bytes calldata spec
    ) external returns (bool success);

    /**
     * @dev Processes a validated action and pays the publisher
     * @param campaignId The campaign ID
     * @param publisherId The publisher who performed the action
     * @param validatorId The validator verifying the action
     * @param actionHash Unique hash identifying the action (prevents double-pay)
     */
    function processAction(
        uint256 campaignId,
        uint256 publisherId,
        uint256 validatorId,
        bytes32 actionHash
    ) external;

    /**
     * @dev Withdraws remaining budget after campaign expiry
     * @param campaignId The campaign ID
     * @return amountWithdrawn The amount of tokens returned to the advertiser
     */
    function withdrawRemainingBudget(uint256 campaignId) external returns (uint256 amountWithdrawn);

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
     * @dev Checks if a campaign is currently active (within time window and has budget)
     * @param campaignId The campaign ID to check
     * @return active True if the campaign is active
     */
    function isCampaignActive(uint256 campaignId) external view returns (bool active);

    /**
     * @dev Returns the remaining budget for a campaign
     * @param campaignId The campaign ID to query
     * @return remaining The remaining budget amount
     */
    function getCampaignRemainingBudget(uint256 campaignId) external view returns (uint256 remaining);

    /**
     * @dev Checks if an action hash has already been processed
     * @param actionHash The action hash to check
     * @return processed True if the action has been processed
     */
    function isActionProcessed(bytes32 actionHash) external view returns (bool processed);
}
