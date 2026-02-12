// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../src/IdentityRegistry.sol";
import "../src/ReputationRegistry.sol";
import "../src/ValidationRegistry.sol";
import "../src/CampaignRegistry.sol";
import "../src/AdRegistry.sol";

/**
 * @title Deploy
 * @dev Deployment script for ERC-XXXX Trustless Agents Reference Implementation
 * @notice Deploys all core registry contracts in the correct order
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying ERC-XXXX Trustless Agents Reference Implementation...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // Deploy IdentityRegistry first (no dependencies)
        console.log("\n1. Deploying IdentityRegistry...");
        IdentityRegistry identityRegistry = new IdentityRegistry();
        console.log("IdentityRegistry deployed at:", address(identityRegistry));
        
        // Deploy ReputationRegistry (depends on IdentityRegistry)
        console.log("\n2. Deploying ReputationRegistry...");
        ReputationRegistry reputationRegistry = new ReputationRegistry(address(identityRegistry));
        console.log("ReputationRegistry deployed at:", address(reputationRegistry));
        
        // Deploy ValidationRegistry (depends on IdentityRegistry)
        console.log("\n3. Deploying ValidationRegistry...");
        ValidationRegistry validationRegistry = new ValidationRegistry(address(identityRegistry));
        console.log("ValidationRegistry deployed at:", address(validationRegistry));

        // Deploy CampaignRegistry (depends on IdentityRegistry)
        console.log("\n4. Deploying CampaignRegistry...");
        CampaignRegistry campaignRegistry = new CampaignRegistry(address(identityRegistry));
        console.log("CampaignRegistry deployed at:", address(campaignRegistry));

        // Deploy AdRegistry (depends on IdentityRegistry and CampaignRegistry)
        console.log("\n5. Deploying AdRegistry...");
        AdRegistry adRegistry = new AdRegistry(address(identityRegistry), address(campaignRegistry));
        console.log("AdRegistry deployed at:", address(adRegistry));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("IdentityRegistry:", address(identityRegistry));
        console.log("ReputationRegistry:", address(reputationRegistry));
        console.log("ValidationRegistry:", address(validationRegistry));
        console.log("CampaignRegistry:", address(campaignRegistry));
        console.log("AdRegistry:", address(adRegistry));
        console.log("\nRegistration fee:", identityRegistry.REGISTRATION_FEE());
        console.log("Validation expiration slots:", validationRegistry.getExpirationSlots());
    }
}