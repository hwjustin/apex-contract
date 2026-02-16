// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

import "./interfaces/IDemoPurchase.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title DemoPurchase
 * @dev Demo contract for purchasing products from advertisers using USDC
 * @notice Minimal implementation - validator and commission logic to be added later
 */
contract DemoPurchase is IDemoPurchase {
    // ============ State Variables ============

    /// @dev Reference to the EIP-8004 Identity Registry (ERC-721)
    IERC721 public immutable identityRegistry;

    /// @dev USDC token on Base Mainnet
    IERC20 public constant USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    /// @dev Counter for product IDs (starts at 1)
    uint256 private _productIdCounter;

    /// @dev Counter for purchase IDs (starts at 1)
    uint256 private _purchaseIdCounter;

    /// @dev Mapping from product ID to product info
    mapping(uint256 => Product) private _products;

    /// @dev Mapping from purchase ID to purchase info
    mapping(uint256 => Purchase) private _purchases;

    /// @dev Mapping from advertiser ID to their product IDs
    mapping(uint256 => uint256[]) private _advertiserProducts;

    // ============ Constructor ============

    constructor(address _identityRegistry) {
        identityRegistry = IERC721(_identityRegistry);
        _productIdCounter = 1;
        _purchaseIdCounter = 1;
    }

    // ============ Write Functions ============

    /**
     * @inheritdoc IDemoPurchase
     */
    function createProduct(
        uint256 advertiserId,
        string calldata name,
        string calldata description,
        uint256 priceAmount
    ) external returns (uint256 productId) {
        // Validate advertiser exists and caller is the owner (ownerOf reverts if not found)
        address advertiserOwner = identityRegistry.ownerOf(advertiserId);
        if (msg.sender != advertiserOwner) {
            revert UnauthorizedProductUpdate();
        }

        // Validate price
        if (priceAmount == 0) {
            revert InvalidPrice();
        }

        // Assign new product ID
        productId = _productIdCounter++;

        // Store product info
        _products[productId] = Product({
            productId: productId,
            advertiserId: advertiserId,
            name: name,
            description: description,
            priceAmount: priceAmount,
            isActive: true
        });

        // Track advertiser's products
        _advertiserProducts[advertiserId].push(productId);

        emit ProductCreated(productId, advertiserId, name, priceAmount);
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function purchaseProduct(uint256 productId) external returns (uint256 purchaseId) {
        // Validate product exists
        Product storage product = _products[productId];
        if (product.productId == 0) {
            revert ProductNotFound();
        }

        // Validate product is active
        if (!product.isActive) {
            revert ProductNotActive();
        }

        // Get advertiser address for payment (ownerOf reverts if not found)
        address advertiserOwner = identityRegistry.ownerOf(product.advertiserId);

        // Transfer USDC from buyer to advertiser (buyer must have approved this contract)
        bool success = USDC.transferFrom(msg.sender, advertiserOwner, product.priceAmount);
        if (!success) {
            revert PaymentFailed();
        }

        // Assign new purchase ID
        purchaseId = _purchaseIdCounter++;

        // Store purchase info
        _purchases[purchaseId] = Purchase({
            purchaseId: purchaseId,
            productId: productId,
            buyer: msg.sender,
            amount: product.priceAmount,
            timestamp: block.timestamp
        });

        emit ProductPurchased(purchaseId, productId, msg.sender, product.priceAmount, block.timestamp);
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function updateProduct(
        uint256 productId,
        string calldata name,
        string calldata description,
        uint256 priceAmount,
        bool isActive
    ) external {
        // Validate product exists
        Product storage product = _products[productId];
        if (product.productId == 0) {
            revert ProductNotFound();
        }

        // Verify caller is the product owner
        address advertiserOwner = identityRegistry.ownerOf(product.advertiserId);
        if (msg.sender != advertiserOwner) {
            revert UnauthorizedProductUpdate();
        }

        // Update fields if provided
        if (bytes(name).length > 0) {
            product.name = name;
        }
        if (bytes(description).length > 0) {
            product.description = description;
        }
        if (priceAmount > 0) {
            product.priceAmount = priceAmount;
        }
        product.isActive = isActive;

        emit ProductUpdated(productId, product.name, product.priceAmount, isActive);
    }

    // ============ Read Functions ============

    /**
     * @inheritdoc IDemoPurchase
     */
    function getProduct(uint256 productId) external view returns (Product memory product) {
        product = _products[productId];
        if (product.productId == 0) {
            revert ProductNotFound();
        }
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function getPurchase(uint256 purchaseId) external view returns (Purchase memory purchase) {
        purchase = _purchases[purchaseId];
        if (purchase.purchaseId == 0) {
            revert ProductNotFound();
        }
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function getProductCount() external view returns (uint256 count) {
        return _productIdCounter - 1;
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function getPurchaseCount() external view returns (uint256 count) {
        return _purchaseIdCounter - 1;
    }

    /**
     * @inheritdoc IDemoPurchase
     */
    function getProductsByAdvertiser(uint256 advertiserId) external view returns (uint256[] memory productIds) {
        return _advertiserProducts[advertiserId];
    }
}
