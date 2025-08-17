// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/HedgeVault.sol";
import "../../contracts/mocks/MockUSDC.sol";

contract HedgeVaultTest is Test {
    HedgeVault public hedgeVault;
    MockUSDC public usdcToken;
    
    address public owner = address(1);
    address public operator = address(2);
    address public policyholder = address(3);
    
    string public constant FLIGHT_NUMBER = "AA123";
    uint256 public constant DEPARTURE_TIME = 1735689600; // Future timestamp
    uint256 public constant REQUIRED_CAPITAL = 200 * 10**6; // 200 USDC
    uint256 public constant DEPOSIT_AMOUNT = 100 * 10**6; // 100 USDC
    
    event CapitalDeposited(address indexed depositor, uint256 amount);
    event CapitalWithdrawn(address indexed withdrawer, uint256 amount);
    event ClaimProcessed(uint256 indexed payout, address indexed policyholder);
    event VaultDeactivated();

    function setUp() public {
        // Deploy mock USDC
        usdcToken = new MockUSDC();
        
        // Deploy hedge vault
        hedgeVault = new HedgeVault(
            address(usdcToken),
            FLIGHT_NUMBER,
            DEPARTURE_TIME,
            REQUIRED_CAPITAL
        );
        
        // Transfer ownership
        hedgeVault.transferOwnership(owner);
        
        // Set up operator
        vm.prank(owner);
        hedgeVault.updateAuthorizedOperator(operator, true);
        
        // Mint USDC to operator
        usdcToken.mint(operator, 1000 * 10**6); // 1000 USDC
    }

    function testConstructor() public {
        assertEq(address(hedgeVault.usdcToken()), address(usdcToken));
        assertEq(hedgeVault.flightNumber(), FLIGHT_NUMBER);
        assertEq(hedgeVault.departureTime(), DEPARTURE_TIME);
        assertEq(hedgeVault.requiredCapital(), REQUIRED_CAPITAL);
        assertTrue(hedgeVault.isActive());
        assertFalse(hedgeVault.isClaimed());
        assertEq(hedgeVault.depositedCapital(), 0);
    }

    function testConstructorInvalidUSDC() public {
        vm.expectRevert("HedgeVault: invalid USDC address");
        new HedgeVault(address(0), FLIGHT_NUMBER, DEPARTURE_TIME, REQUIRED_CAPITAL);
    }

    function testConstructorEmptyFlightNumber() public {
        vm.expectRevert("HedgeVault: flight number cannot be empty");
        new HedgeVault(address(usdcToken), "", DEPARTURE_TIME, REQUIRED_CAPITAL);
    }

    function testConstructorPastDepartureTime() public {
        vm.expectRevert("HedgeVault: departure time must be in the future");
        new HedgeVault(address(usdcToken), FLIGHT_NUMBER, block.timestamp - 1 days, REQUIRED_CAPITAL);
    }

    function testConstructorZeroRequiredCapital() public {
        vm.expectRevert("HedgeVault: required capital must be greater than 0");
        new HedgeVault(address(usdcToken), FLIGHT_NUMBER, DEPARTURE_TIME, 0);
    }

    function testDepositCapital() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        
        assertEq(hedgeVault.depositedCapital(), DEPOSIT_AMOUNT);
        assertEq(usdcToken.balanceOf(address(hedgeVault)), DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testDepositCapitalNotAuthorized() public {
        address unauthorized = address(4);
        usdcToken.mint(unauthorized, DEPOSIT_AMOUNT);
        
        vm.startPrank(unauthorized);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        
        vm.expectRevert("HedgeVault: not authorized");
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testDepositCapitalZeroAmount() public {
        vm.startPrank(operator);
        
        vm.expectRevert("HedgeVault: cannot deposit 0");
        hedgeVault.depositCapital(0);
        
        vm.stopPrank();
    }

    function testDepositCapitalExceedsRequired() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL + 1);
        
        // First deposit the required amount
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        
        // Try to deposit more
        vm.expectRevert("HedgeVault: exceeds required capital");
        hedgeVault.depositCapital(1);
        
        vm.stopPrank();
    }

    function testWithdrawCapital() public {
        // First deposit
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        
        uint256 initialBalance = usdcToken.balanceOf(operator);
        
        // Then withdraw
        hedgeVault.withdrawCapital(DEPOSIT_AMOUNT);
        
        assertEq(hedgeVault.depositedCapital(), 0);
        assertEq(usdcToken.balanceOf(operator), initialBalance);
        
        vm.stopPrank();
    }

    function testWithdrawCapitalInsufficient() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        
        vm.expectRevert("HedgeVault: insufficient capital");
        hedgeVault.withdrawCapital(DEPOSIT_AMOUNT + 1);
        
        vm.stopPrank();
    }

    function testProcessClaim() public {
        // First deposit
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        vm.stopPrank();
        
        uint256 payoutAmount = 200 * 10**6; // 200 USDC
        uint256 initialBalance = usdcToken.balanceOf(policyholder);
        
        // Process claim
        vm.prank(operator);
        hedgeVault.processClaim(policyholder, payoutAmount);
        
        // Verify claim processing
        assertTrue(hedgeVault.isClaimed());
        assertFalse(hedgeVault.isActive());
        assertEq(hedgeVault.depositedCapital(), REQUIRED_CAPITAL - payoutAmount);
        assertEq(usdcToken.balanceOf(policyholder), initialBalance + payoutAmount);
    }

    function testProcessClaimInvalidPolicyholder() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        vm.stopPrank();
        
        vm.prank(operator);
        vm.expectRevert("HedgeVault: invalid policyholder");
        hedgeVault.processClaim(address(0), REQUIRED_CAPITAL);
    }

    function testProcessClaimInvalidPayoutAmount() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        vm.stopPrank();
        
        vm.prank(operator);
        vm.expectRevert("HedgeVault: invalid payout amount");
        hedgeVault.processClaim(policyholder, 0);
    }

    function testProcessClaimInsufficientCapital() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        vm.prank(operator);
        vm.expectRevert("HedgeVault: insufficient capital for payout");
        hedgeVault.processClaim(policyholder, REQUIRED_CAPITAL);
    }

    function testProcessClaimAlreadyClaimed() public {
        // First deposit and claim
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        hedgeVault.processClaim(policyholder, 100 * 10**6);
        vm.stopPrank();
        
        // Try to claim again
        vm.prank(operator);
        vm.expectRevert("HedgeVault: vault already claimed");
        hedgeVault.processClaim(policyholder, 100 * 10**6);
    }

    function testDeactivateVault() public {
        // Fast forward past departure time + 24 hours
        vm.warp(DEPARTURE_TIME + 25 hours);
        
        vm.prank(operator);
        hedgeVault.deactivateVault();
        
        assertFalse(hedgeVault.isActive());
    }

    function testDeactivateVaultTooEarly() public {
        // Fast forward to just after departure time
        vm.warp(DEPARTURE_TIME + 23 hours);
        
        vm.prank(operator);
        vm.expectRevert("HedgeVault: flight not yet expired");
        hedgeVault.deactivateVault();
    }

    function testGetVaultStatus() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        (bool isActive, bool isClaimed, uint256 depositedCapital, uint256 requiredCapital) = hedgeVault.getVaultStatus();
        
        assertTrue(isActive);
        assertFalse(isClaimed);
        assertEq(depositedCapital, DEPOSIT_AMOUNT);
        assertEq(requiredCapital, REQUIRED_CAPITAL);
    }

    function testIsFullyFunded() public {
        assertFalse(hedgeVault.isFullyFunded());
        
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        vm.stopPrank();
        
        assertTrue(hedgeVault.isFullyFunded());
    }

    function testGetRemainingCapitalNeeded() public {
        assertEq(hedgeVault.getRemainingCapitalNeeded(), REQUIRED_CAPITAL);
        
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        assertEq(hedgeVault.getRemainingCapitalNeeded(), REQUIRED_CAPITAL - DEPOSIT_AMOUNT);
        
        // Fully fund
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL - DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(REQUIRED_CAPITAL - DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        assertEq(hedgeVault.getRemainingCapitalNeeded(), 0);
    }

    function testUpdateAuthorizedOperator() public {
        address newOperator = address(4);
        
        vm.prank(owner);
        hedgeVault.updateAuthorizedOperator(newOperator, true);
        
        assertTrue(hedgeVault.authorizedOperators(newOperator));
        
        vm.prank(owner);
        hedgeVault.updateAuthorizedOperator(newOperator, false);
        
        assertFalse(hedgeVault.authorizedOperators(newOperator));
    }

    function testUpdateAuthorizedOperatorNotOwner() public {
        address newOperator = address(4);
        
        vm.expectRevert();
        hedgeVault.updateAuthorizedOperator(newOperator, true);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        hedgeVault.pause();
        
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        
        vm.expectRevert("Pausable: paused");
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        
        vm.stopPrank();
        
        vm.prank(owner);
        hedgeVault.unpause();
        
        // Should work again
        vm.startPrank(operator);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Mint some tokens to the vault
        usdcToken.mint(address(hedgeVault), 1000 * 10**6);
        
        uint256 initialBalance = usdcToken.balanceOf(owner);
        
        vm.prank(owner);
        hedgeVault.emergencyWithdraw(address(usdcToken), 500 * 10**6);
        
        uint256 finalBalance = usdcToken.balanceOf(owner);
        assertEq(finalBalance - initialBalance, 500 * 10**6);
    }

    function testEmergencyWithdrawNotOwner() public {
        vm.expectRevert();
        hedgeVault.emergencyWithdraw(address(usdcToken), 500 * 10**6);
    }

    function testGetVaultInfo() public {
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        (string memory flightNumber, uint256 departureTime, uint256 requiredCapital, uint256 depositedCapital) = hedgeVault.getVaultInfo();
        
        assertEq(flightNumber, FLIGHT_NUMBER);
        assertEq(departureTime, DEPARTURE_TIME);
        assertEq(requiredCapital, REQUIRED_CAPITAL);
        assertEq(depositedCapital, DEPOSIT_AMOUNT);
    }

    function testDepositCapitalAfterClaim() public {
        // First deposit and claim
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        hedgeVault.processClaim(policyholder, 100 * 10**6);
        vm.stopPrank();
        
        // Try to deposit after claim
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), DEPOSIT_AMOUNT);
        vm.expectRevert("HedgeVault: vault already claimed");
        hedgeVault.depositCapital(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testWithdrawCapitalAfterClaim() public {
        // First deposit and claim
        vm.startPrank(operator);
        usdcToken.approve(address(hedgeVault), REQUIRED_CAPITAL);
        hedgeVault.depositCapital(REQUIRED_CAPITAL);
        hedgeVault.processClaim(policyholder, 100 * 10**6);
        vm.stopPrank();
        
        // Try to withdraw after claim
        vm.startPrank(operator);
        vm.expectRevert("HedgeVault: vault already claimed");
        hedgeVault.withdrawCapital(50 * 10**6);
        vm.stopPrank();
    }
} 