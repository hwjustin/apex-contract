// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAdRegistry
 * @dev Interface for the Ad Registry
 * @notice Manages individual ad transactions within campaigns
 */
interface IAdRegistry {
    // ============ Structs ============

    /**
     * @dev Represents an individual ad transaction
     * @param adId Unique identifier for the ad
     * @param campaignId ID of the campaign this ad belongs to
     * @param advertiserId ID of the advertiser
     * @param publisherId ID of the publisher completing the ad job
     * @param startTime Timestamp when the ad started
     * @param metadata Additional data about the ad (e.g., performance metrics, content hash)
     */
    struct Ad {
        uint256 adId;
        uint256 campaignId;
        uint256 advertiserId;
        uint256 publisherId;
        uint256 startTime;
        bytes metadata;
    }

    // ============ Events ============

    /**
     * @dev Emitted when a new ad is created
     * @param adId The ID of the newly created ad
     * @param campaignId The campaign this ad belongs to
     * @param advertiserId The advertiser ID
     * @param publisherId The publisher ID
     * @param startTime When the ad started
     */
    event AdCreated(
        uint256 indexed adId,
        uint256 indexed campaignId,
        uint256 indexed advertiserId,
        uint256 publisherId,
        uint256 startTime
    );

    /**
     * @dev Emitted when an ad is updated
     * @param adId The ID of the updated ad
     * @param metadata The new metadata
     */
    event AdUpdated(uint256 indexed adId, bytes metadata);

    // ============ Errors ============

    error AdNotFound();
    error CampaignNotFound();
    error CampaignNotActive();
    error AdvertiserNotFound();
    error PublisherNotFound();
    error UnauthorizedCaller();
    error InvalidStartTime();

    // ============ Write Functions ============

    /**
     * @dev Creates a new ad transaction
     * @param campaignId The campaign this ad belongs to
     * @param publisherId The publisher completing this ad job
     * @param startTime When the ad started
     * @param metadata Additional data about the ad
     * @return adId The ID of the newly created ad
     */
    function createAd(
        uint256 campaignId,
        uint256 publisherId,
        uint256 startTime,
        bytes calldata metadata
    ) external returns (uint256 adId);

    /**
     * @dev Updates an existing ad's metadata
     * @param adId The ID of the ad to update
     * @param metadata The new metadata
     * @return success True if update was successful
     */
    function updateAd(
        uint256 adId,
        bytes calldata metadata
    ) external returns (bool success);

    // ============ Read Functions ============

    /**
     * @dev Gets ad information by ID
     * @param adId The ID of the ad
     * @return ad The ad information
     */
    function getAd(uint256 adId) external view returns (Ad memory ad);

    /**
     * @dev Gets all ads for a specific campaign
     * @param campaignId The campaign ID
     * @return adIds Array of ad IDs
     */
    function getAdsByCampaign(uint256 campaignId) external view returns (uint256[] memory adIds);

    /**
     * @dev Gets all ads for a specific publisher
     * @param publisherId The publisher ID
     * @return adIds Array of ad IDs
     */
    function getAdsByPublisher(uint256 publisherId) external view returns (uint256[] memory adIds);

    /**
     * @dev Gets all ads for a specific advertiser
     * @param advertiserId The advertiser ID
     * @return adIds Array of ad IDs
     */
    function getAdsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory adIds);

    /**
     * @dev Gets the total number of ads
     * @return count The total ad count
     */
    function getAdCount() external view returns (uint256 count);

    /**
     * @dev Checks if an ad exists
     * @param adId The ad ID to check
     * @return exists True if the ad exists
     */
    function adExists(uint256 adId) external view returns (bool exists);
}
