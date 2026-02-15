// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

/**
 * @title IDemoPurchase
 * @dev Interface for the Demo Purchase contract
 * @notice Enables users to purchase products from advertisers using USDC
 */
interface IDemoPurchase {
    // ============ Structs ============

    struct Product {
        uint256 productId;
        uint256 advertiserId;      // Owner of the product (agent ID from IdentityRegistry)
        string name;
        string description;
        uint256 priceAmount;       // Price in USDC (6 decimals)
        bool isActive;
    }

    struct Purchase {
        uint256 purchaseId;
        uint256 productId;
        address buyer;
        uint256 amount;
        uint256 timestamp;
    }

    // ============ Events ============

    event ProductCreated(
        uint256 indexed productId,
        uint256 indexed advertiserId,
        string name,
        uint256 priceAmount
    );

    event ProductUpdated(
        uint256 indexed productId,
        string name,
        uint256 priceAmount,
        bool isActive
    );

    event ProductPurchased(
        uint256 indexed purchaseId,
        uint256 indexed productId,
        address indexed buyer,
        uint256 amount,
        uint256 timestamp
    );

    // ============ Errors ============

    error ProductNotFound();
    error ProductNotActive();
    error InvalidPrice();
    error InvalidPaymentAmount();
    error AdvertiserNotRegistered();
    error UnauthorizedProductUpdate();
    error PaymentFailed();

    // ============ Write Functions ============

    /**
     * @dev Create a new purchasable product
     * @param advertiserId The agent ID of the advertiser (must be registered in IdentityRegistry)
     * @param name The product name
     * @param description The product description
     * @param priceAmount The price in USDC (6 decimals, e.g. 1000000 = 1 USDC)
     * @return productId The unique identifier assigned to the product
     */
    function createProduct(
        uint256 advertiserId,
        string calldata name,
        string calldata description,
        uint256 priceAmount
    ) external returns (uint256 productId);

    /**
     * @dev Purchase a product with USDC
     * @param productId The product to purchase
     * @return purchaseId The unique identifier assigned to the purchase
     * @notice Buyer must approve USDC spending before calling. Payment goes directly to the advertiser.
     */
    function purchaseProduct(uint256 productId) external returns (uint256 purchaseId);

    /**
     * @dev Update a product's details
     * @param productId The product to update
     * @param name New name (empty string to keep current)
     * @param description New description (empty string to keep current)
     * @param priceAmount New price (0 to keep current)
     * @param isActive Whether the product is active
     */
    function updateProduct(
        uint256 productId,
        string calldata name,
        string calldata description,
        uint256 priceAmount,
        bool isActive
    ) external;

    // ============ Read Functions ============

    /**
     * @dev Get product details by ID
     * @param productId The product's unique identifier
     * @return product The product information
     */
    function getProduct(uint256 productId) external view returns (Product memory product);

    /**
     * @dev Get purchase details by ID
     * @param purchaseId The purchase's unique identifier
     * @return purchase The purchase information
     */
    function getPurchase(uint256 purchaseId) external view returns (Purchase memory purchase);

    /**
     * @dev Get the total number of products
     * @return count The total count of products
     */
    function getProductCount() external view returns (uint256 count);

    /**
     * @dev Get the total number of purchases
     * @return count The total count of purchases
     */
    function getPurchaseCount() external view returns (uint256 count);

    /**
     * @dev Get all products by an advertiser
     * @param advertiserId The agent ID of the advertiser
     * @return productIds Array of product IDs owned by the advertiser
     */
    function getProductsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory productIds);
}
