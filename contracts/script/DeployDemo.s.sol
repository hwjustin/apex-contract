// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 APEX Network
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "../demo/DemoPurchase.sol";

/**
 * @title DeployDemo
 * @dev Deployment script for DemoPurchase contract on Base Sepolia
 * @notice Deploys the demo purchase contract using existing EIP-8004 Identity Registry
 *
 * Usage:
 *   forge script script/DeployDemo.s.sol --rpc-url base_sepolia --broadcast --verify
 */
contract DeployDemo is Script {
    /// @dev EIP-8004 Identity Registry on Base Mainnet
    address constant IDENTITY_REGISTRY = 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying DemoPurchase contract on Base Sepolia...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("IdentityRegistry:", IDENTITY_REGISTRY);

        // Deploy DemoPurchase
        DemoPurchase demoPurchase = new DemoPurchase(IDENTITY_REGISTRY);
        console.log("\nDemoPurchase deployed at:", address(demoPurchase));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("DemoPurchase:", address(demoPurchase));
        console.log("IdentityRegistry:", IDENTITY_REGISTRY);
    }
}
