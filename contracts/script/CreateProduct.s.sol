// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../demo/DemoPurchase.sol";

/**
 * @title CreateProduct
 * @dev Script to create a product in the deployed DemoPurchase contract on Base Sepolia
 * @notice Prerequisites:
 *   1. Run DeployDemo.s.sol to deploy DemoPurchase contract
 *   2. Update DEMO_PURCHASE constant with deployed address
 *   3. Ensure your wallet is registered as an agent in IdentityRegistry
 *   4. Update advertiserId with your registered agent ID
 *   5. Set ADVERTISER_PRIVATE_KEY env var - must match the agentAddress for that advertiserId
 *
 * Usage:
 *   forge script script/CreateProduct.s.sol --rpc-url base_sepolia --broadcast
 */
contract CreateProduct is Script {
    /// @dev EIP-8004 Identity Registry on Base Sepolia
    address constant IDENTITY_REGISTRY = 0x8004A818BFB912233c491871b3d84c89A494BD9e;

    /// @dev DemoPurchase contract on Base Sepolia
    address constant DEMO_PURCHASE = 0xe9A8C0a1f5aC4788840d8820A10555f9da8bF38D;

    function run() external {
        require(DEMO_PURCHASE != address(0), "Please update DEMO_PURCHASE address first");

        uint256 advertiserPrivateKey = vm.envUint("ADVERTISER_PRIVATE_KEY");
        address advertiserAddress = vm.addr(advertiserPrivateKey);

        // Product details - customize these
        uint256 advertiserId = 632;
        string memory productName = "Demo Product";
        string memory productDescription = "This is a demo product for testing";
        uint256 productPrice = 1 * 1e6; // 10 USDC (6 decimals)

        console.log("Creating product in DemoPurchase contract...");
        console.log("Advertiser address:", advertiserAddress);
        console.log("Advertiser ID:", advertiserId);
        console.log("Product name:", productName);
        console.log("Product price:", productPrice);

        // Connect to deployed contract
        DemoPurchase demoPurchase = DemoPurchase(DEMO_PURCHASE);

        vm.startBroadcast(advertiserPrivateKey);

        // Create the product
        uint256 productId = demoPurchase.createProduct(
            advertiserId,
            productName,
            productDescription,
            productPrice
        );

        vm.stopBroadcast();

        console.log("\n=== Product Created ===");
        console.log("Product ID:", productId);
        console.log("View on contract:", DEMO_PURCHASE);

        // Read back the product to verify
        IDemoPurchase.Product memory product = demoPurchase.getProduct(productId);
        console.log("\n=== Product Details ===");
        console.log("Name:", product.name);
        console.log("Description:", product.description);
        console.log("Price:", product.priceAmount);
        console.log("Active:", product.isActive);
    }

    // Alternative function to create product with custom parameters
    function createCustomProduct(
        address demoPurchaseAddress,
        uint256 advertiserId,
        string memory name,
        string memory description,
        uint256 price
    ) external {
        uint256 advertiserPrivateKey = vm.envUint("ADVERTISER_PRIVATE_KEY");

        DemoPurchase demoPurchase = DemoPurchase(demoPurchaseAddress);

        vm.startBroadcast(advertiserPrivateKey);

        uint256 productId = demoPurchase.createProduct(
            advertiserId,
            name,
            description,
            price
        );

        vm.stopBroadcast();

        console.log("Product created with ID:", productId);
    }
}
