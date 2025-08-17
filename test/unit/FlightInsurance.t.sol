// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/FlightInsurance.sol";
import "../../contracts/core/RiskVault.sol";
import "../../contracts/mocks/MockUSDC.sol";
import "../../contracts/mocks/MockOracle.sol";

contract FlightInsuranceTest is Test {
    FlightInsurance public flightInsurance;
    RiskVault public riskVault;
    MockUSDC public usdcToken;
    MockOracle public oracle;
    
    address public owner = address(1);
    address public user = address(2);
    address public oracleOperator = address(3);
    
    uint256 public constant PREMIUM_AMOUNT = 50 * 10**6; // 50 USDC
    uint256 public constant PAYOUT_AMOUNT = 200 * 10**6; // 200 USDC
    uint256 public constant CAPITAL_RATIO = 4; // 4:1 ratio
    
    event PolicyCreated(
        uint256 indexed policyId,
        address indexed policyholder,
        string flightNumber,
        uint256 departureTime,
        uint256 premium,
        uint256 payout
    );

    event ClaimSettled(
        uint256 indexed policyId,
        address indexed policyholder,
        uint256 payout,
        uint256 delayHours
    );

    function setUp() public {
        vm.startPrank(owner);
        // Deploy mock contracts
        usdcToken = new MockUSDC();
        oracle = new MockOracle();
        
        // Deploy risk vault
        riskVault = new RiskVault(
            address(usdcToken),
            "Risk Vault",
            "RISK"
        );
        
        // Deploy flight insurance
        flightInsurance = new FlightInsurance(
            address(usdcToken),
            address(riskVault),
            address(oracle)
        );
        
        // Set up permissions
        riskVault.transferOwnership(owner);
        riskVault.updateAuthorizedDepositor(address(flightInsurance), true);
        flightInsurance.transferOwnership(owner);
        
        // Mint USDC to user
        usdcToken.mint(user, 1000 * 10**6); // 1000 USDC
        
        // Mint USDC to risk vault for capital
        usdcToken.mint(address(riskVault), 10000 * 10**6); // 10000 USDC
        riskVault.authorizedDeposit(10000 * 10**6);
        vm.stopPrank();
    }

    function testCreatePolicy() public {
        vm.startPrank(user);
        
        // Approve USDC spending
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        
        // Create policy
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        
        // Verify policy creation
        assertEq(policyId, 1);
        
        FlightInsurance.Policy memory policy = flightInsurance.getPolicy(policyId);
        assertEq(policy.policyholder, user);
        assertEq(policy.flightNumber, "AA123");
        assertEq(policy.premium, PREMIUM_AMOUNT);
        assertEq(policy.payout, PAYOUT_AMOUNT);
        assertTrue(policy.isActive);
        assertFalse(policy.isClaimed);
        
        vm.stopPrank();
    }

    function testCreatePolicyInsufficientCapitalRatio() public {
        // Deploy new risk vault with minimal capital
        RiskVault newRiskVault = new RiskVault(
            address(usdcToken),
            "New Risk Vault",
            "NRISK"
        );
        
        FlightInsurance newFlightInsurance = new FlightInsurance(
            address(usdcToken),
            address(newRiskVault),
            address(oracle)
        );
        
        newRiskVault.updateAuthorizedDepositor(address(newFlightInsurance), true);
        
        vm.startPrank(user);
        usdcToken.approve(address(newFlightInsurance), PREMIUM_AMOUNT);
        
        // Should fail due to insufficient capital ratio
        vm.expectRevert("FlightInsurance: insufficient capital ratio");
        newFlightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        
        vm.stopPrank();
    }

    function testCreatePolicyInvalidFlightNumber() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        
        vm.expectRevert("FlightInsurance: flight number cannot be empty");
        flightInsurance.createPolicy("", block.timestamp + 1 days);
        
        vm.stopPrank();
    }

    function testCreatePolicyPastDepartureTime() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        
        vm.expectRevert("FlightInsurance: departure time must be in the future");
        flightInsurance.createPolicy("AA123", block.timestamp - 1 days);
        
        vm.stopPrank();
    }

    function testCreatePolicyDuplicateFlight() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT * 2);
        
        // Create first policy
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        
        // Try to create duplicate policy
        vm.expectRevert("FlightInsurance: policy already exists for this flight");
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        
        vm.stopPrank();
    }

    function testSettleClaim() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Settle claim as oracle
        vm.prank(address(oracle));
        flightInsurance.settleClaim(policyId, 8); // 8 hours delay
        
        // Verify claim settlement
        FlightInsurance.Policy memory policy = flightInsurance.getPolicy(policyId);
        assertTrue(policy.isClaimed);
        assertFalse(policy.isActive);
        
        // Verify user received payout
        assertEq(usdcToken.balanceOf(user), 1000 * 10**6 - PREMIUM_AMOUNT + PAYOUT_AMOUNT);
    }

    function testSettleClaimInsufficientDelay() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Try to settle claim with insufficient delay
        vm.prank(address(oracle));
        vm.expectRevert("FlightInsurance: delay below threshold");
        flightInsurance.settleClaim(policyId, 4); // 4 hours delay (below 6 hour threshold)
    }

    function testSettleClaimNotOracle() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Try to settle claim as non-oracle
        vm.expectRevert("FlightInsurance: caller is not oracle");
        flightInsurance.settleClaim(policyId, 8);
    }

    function testSettleClaimAlreadyClaimed() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Settle claim first time
        vm.prank(address(oracle));
        flightInsurance.settleClaim(policyId, 8);
        
        // Try to settle claim again
        vm.prank(address(oracle));
        vm.expectRevert("FlightInsurance: policy already claimed");
        flightInsurance.settleClaim(policyId, 8);
    }

    function testExpirePolicy() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Fast forward past expiration time
        vm.warp(block.timestamp + 1 days + 25 hours);
        
        // Expire policy
        flightInsurance.expirePolicy(policyId);
        
        // Verify policy expiration
        FlightInsurance.Policy memory policy = flightInsurance.getPolicy(policyId);
        assertFalse(policy.isActive);
    }

    function testExpirePolicyTooEarly() public {
        // Create policy
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        uint256 policyId = flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
        
        // Try to expire policy too early
        vm.expectRevert("FlightInsurance: policy not yet expired");
        flightInsurance.expirePolicy(policyId);
    }

    function testGetPolicyholderPolicies() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT * 3);
        
        // Create multiple policies
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        flightInsurance.createPolicy("AA124", block.timestamp + 2 days);
        flightInsurance.createPolicy("AA125", block.timestamp + 3 days);
        
        vm.stopPrank();
        
        // Get user's policies
        uint256[] memory policies = flightInsurance.getPolicyholderPolicies(user);
        assertEq(policies.length, 3);
        assertEq(policies[0], 1);
        assertEq(policies[1], 2);
        assertEq(policies[2], 3);
    }

    function testGetActivePolicies() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT * 2);
        
        // Create policies
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        flightInsurance.createPolicy("AA124", block.timestamp + 2 days);
        
        vm.stopPrank();
        
        // Settle one claim
        vm.prank(address(oracle));
        flightInsurance.settleClaim(1, 8);
        
        // Get active policies
        uint256[] memory activePolicies = flightInsurance.getActivePolicies();
        assertEq(activePolicies.length, 1);
        assertEq(activePolicies[0], 2);
    }

    function testUpdateOracle() public {
        address newOracle = address(4);
        
        vm.prank(owner);
        flightInsurance.updateOracle(newOracle);
        
        // Verify oracle update
        // Note: We can't directly access the oracle state variable, but we can test by trying to call a function
        // that requires oracle access with the old oracle address
        vm.prank(address(oracle));
        vm.expectRevert("FlightInsurance: caller is not oracle");
        flightInsurance.settleClaim(1, 8);
    }

    function testUpdateOracleNotOwner() public {
        address newOracle = address(4);
        
        vm.expectRevert();
        flightInsurance.updateOracle(newOracle);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        flightInsurance.pause();
        
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT);
        
        vm.expectRevert("Pausable: paused");
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        
        vm.stopPrank();
        
        vm.prank(owner);
        flightInsurance.unpause();
        
        // Should work again
        vm.startPrank(user);
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Mint some tokens to the contract
        usdcToken.mint(address(flightInsurance), 1000 * 10**6);
        
        uint256 initialBalance = usdcToken.balanceOf(owner);
        
        vm.prank(owner);
        flightInsurance.emergencyWithdraw(address(usdcToken), 500 * 10**6);
        
        uint256 finalBalance = usdcToken.balanceOf(owner);
        assertEq(finalBalance - initialBalance, 500 * 10**6);
    }

    function testGetTotalStats() public {
        vm.startPrank(user);
        usdcToken.approve(address(flightInsurance), PREMIUM_AMOUNT * 2);
        
        // Create policies
        flightInsurance.createPolicy("AA123", block.timestamp + 1 days);
        flightInsurance.createPolicy("AA124", block.timestamp + 2 days);
        
        vm.stopPrank();
        
        // Verify stats
        assertEq(flightInsurance.getTotalPolicies(), 2);
        assertEq(flightInsurance.getTotalPremiums(), PREMIUM_AMOUNT * 2);
        assertEq(flightInsurance.getTotalPayouts(), 0);
        
        // Settle a claim
        vm.prank(address(oracle));
        flightInsurance.settleClaim(1, 8);
        
        assertEq(flightInsurance.getTotalPayouts(), PAYOUT_AMOUNT);
    }
} 