// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/CampaignRegistry.sol";
import "../src/AdRegistry.sol";

/**
 * @title Deploy
 * @dev Deployment script for APEX Campaign and Ad Registries
 * @notice Deploys CampaignRegistry and AdRegistry using the existing EIP-8004 Identity Registry
 */
contract Deploy is Script {
    /// @dev EIP-8004 Identity Registry on Base Sepolia
    address constant IDENTITY_REGISTRY = 0x8004A818BFB912233c491871b3d84c89A494BD9e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying APEX Campaign and Ad Registries...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Using EIP-8004 Identity Registry at:", IDENTITY_REGISTRY);

        // Deploy CampaignRegistry (depends on EIP-8004 Identity Registry)
        console.log("\n1. Deploying CampaignRegistry...");
        CampaignRegistry campaignRegistry = new CampaignRegistry(IDENTITY_REGISTRY);
        console.log("CampaignRegistry deployed at:", address(campaignRegistry));

        // Deploy AdRegistry (depends on Identity Registry and CampaignRegistry)
        console.log("\n2. Deploying AdRegistry...");
        AdRegistry adRegistry = new AdRegistry(IDENTITY_REGISTRY, address(campaignRegistry));
        console.log("AdRegistry deployed at:", address(adRegistry));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("IdentityRegistry (EIP-8004):", IDENTITY_REGISTRY);
        console.log("CampaignRegistry:", address(campaignRegistry));
        console.log("AdRegistry:", address(adRegistry));
    }
}
