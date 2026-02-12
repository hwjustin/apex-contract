// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IAdRegistry.sol";
import "./interfaces/IIdentityRegistry.sol";
import "./interfaces/ICampaignRegistry.sol";

/**
 * @title AdRegistry
 * @dev Registry for managing individual ad transactions within campaigns
 * @notice Tracks ad jobs completed by publishers within advertiser campaigns
 */
contract AdRegistry is IAdRegistry {
    // ============ State Variables ============

    /// @dev Reference to the IdentityRegistry for agent validation
    IIdentityRegistry public immutable identityRegistry;

    /// @dev Reference to the CampaignRegistry for campaign validation
    ICampaignRegistry public immutable campaignRegistry;

    /// @dev Counter for ad IDs
    uint256 private _adIdCounter;

    /// @dev Mapping from ad ID to ad info
    mapping(uint256 => Ad) private _ads;

    /// @dev Mapping from campaign ID to their ad IDs
    mapping(uint256 => uint256[]) private _campaignAds;

    /// @dev Mapping from publisher ID to their ad IDs
    mapping(uint256 => uint256[]) private _publisherAds;

    /// @dev Mapping from advertiser ID to their ad IDs
    mapping(uint256 => uint256[]) private _advertiserAds;

    // ============ Constructor ============

    /**
     * @dev Constructor sets the identity and campaign registry references
     * @param _identityRegistry Address of the IdentityRegistry contract
     * @param _campaignRegistry Address of the CampaignRegistry contract
     */
    constructor(address _identityRegistry, address _campaignRegistry) {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        campaignRegistry = ICampaignRegistry(_campaignRegistry);
        // Start ad IDs from 1 (0 is reserved for "not found")
        _adIdCounter = 1;
    }

    // ============ Write Functions ============

    /**
     * @inheritdoc IAdRegistry
     */
    function createAd(
        uint256 campaignId,
        uint256 publisherId,
        uint256 startTime,
        bytes calldata metadata
    ) external returns (uint256 adId) {
        // Validate campaign exists and is active
        if (!campaignRegistry.campaignExists(campaignId)) {
            revert CampaignNotFound();
        }
        if (!campaignRegistry.isCampaignActive(campaignId)) {
            revert CampaignNotActive();
        }

        // Get campaign info to extract advertiser ID
        ICampaignRegistry.Campaign memory campaign = campaignRegistry.getCampaign(campaignId);
        uint256 advertiserId = campaign.advertiserId;

        // Validate advertiser exists
        IIdentityRegistry.AgentInfo memory advertiserInfo = identityRegistry.getAgent(advertiserId);
        if (advertiserInfo.agentId == 0) {
            revert AdvertiserNotFound();
        }

        // Validate publisher exists
        IIdentityRegistry.AgentInfo memory publisherInfo = identityRegistry.getAgent(publisherId);
        if (publisherInfo.agentId == 0) {
            revert PublisherNotFound();
        }

        // Allow either advertiser or publisher to create the ad
        if (advertiserInfo.agentAddress != msg.sender && publisherInfo.agentAddress != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Validate start time
        if (startTime > block.timestamp) {
            revert InvalidStartTime();
        }

        // Assign new ad ID
        adId = _adIdCounter++;

        // Store ad info
        _ads[adId] = Ad({
            adId: adId,
            campaignId: campaignId,
            advertiserId: advertiserId,
            publisherId: publisherId,
            startTime: startTime,
            metadata: metadata
        });

        // Track relationships
        _campaignAds[campaignId].push(adId);
        _publisherAds[publisherId].push(adId);
        _advertiserAds[advertiserId].push(adId);

        emit AdCreated(adId, campaignId, advertiserId, publisherId, startTime);
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function updateAd(
        uint256 adId,
        bytes calldata metadata
    ) external returns (bool success) {
        // Validate ad exists
        Ad storage ad = _ads[adId];
        if (ad.adId == 0) {
            revert AdNotFound();
        }

        // Validate caller is authorized (must be the advertiser)
        IIdentityRegistry.AgentInfo memory advertiserInfo = identityRegistry.getAgent(ad.advertiserId);
        if (advertiserInfo.agentAddress != msg.sender) {
            revert UnauthorizedCaller();
        }

        // Update metadata
        ad.metadata = metadata;

        emit AdUpdated(adId, metadata);
        return true;
    }

    // ============ Read Functions ============

    /**
     * @inheritdoc IAdRegistry
     */
    function getAd(uint256 adId) external view returns (Ad memory ad) {
        ad = _ads[adId];
        if (ad.adId == 0) {
            revert AdNotFound();
        }
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function getAdsByCampaign(uint256 campaignId) external view returns (uint256[] memory adIds) {
        return _campaignAds[campaignId];
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function getAdsByPublisher(uint256 publisherId) external view returns (uint256[] memory adIds) {
        return _publisherAds[publisherId];
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function getAdsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory adIds) {
        return _advertiserAds[advertiserId];
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function getAdCount() external view returns (uint256 count) {
        return _adIdCounter - 1;
    }

    /**
     * @inheritdoc IAdRegistry
     */
    function adExists(uint256 adId) external view returns (bool exists) {
        return _ads[adId].adId != 0;
    }
}
