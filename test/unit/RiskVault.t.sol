// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/core/RiskVault.sol";
import "../../contracts/mocks/MockUSDC.sol";

contract RiskVaultTest is Test {
    RiskVault public riskVault;
    MockUSDC public usdcToken;
    
    address public owner = address(1);
    address public user = address(2);
    address public authorizedDepositor = address(3);
    
    uint256 public constant DEPOSIT_AMOUNT = 1000 * 10**6; // 1000 USDC
    
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    function setUp() public {
        // Deploy mock USDC
        usdcToken = new MockUSDC();
        
        // Deploy risk vault
        riskVault = new RiskVault(
            address(usdcToken),
            "Risk Vault",
            "RISK"
        );
        
        // Transfer ownership
        riskVault.transferOwnership(owner);
        
        // Mint USDC to user
        usdcToken.mint(user, 10000 * 10**6); // 10000 USDC
    }

    function testConstructor() public {
        assertEq(address(riskVault.asset()), address(usdcToken));
        assertEq(riskVault.name(), "Risk Vault");
        assertEq(riskVault.symbol(), "RISK");
        assertEq(riskVault.decimals(), 6);
    }

    function testDeposit() public {
        vm.startPrank(user);
        
        // Approve USDC spending
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        // Deposit assets
        uint256 shares = riskVault.deposit(DEPOSIT_AMOUNT, user);
        
        // Verify deposit
        assertEq(shares, DEPOSIT_AMOUNT); // First deposit should be 1:1
        assertEq(riskVault.balanceOf(user), DEPOSIT_AMOUNT);
        assertEq(riskVault.totalAssets(), DEPOSIT_AMOUNT);
        assertEq(riskVault.totalShares(), DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testDepositZeroAmount() public {
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), 0);
        
        vm.expectRevert("RiskVault: cannot deposit 0");
        riskVault.deposit(0, user);
        
        vm.stopPrank();
    }

    function testDepositInvalidReceiver() public {
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        vm.expectRevert("RiskVault: invalid receiver");
        riskVault.deposit(DEPOSIT_AMOUNT, address(0));
        
        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(user);
        
        // Approve USDC spending
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        // Mint shares
        uint256 assets = riskVault.mint(DEPOSIT_AMOUNT, user);
        
        // Verify mint
        assertEq(assets, DEPOSIT_AMOUNT); // First mint should be 1:1
        assertEq(riskVault.balanceOf(user), DEPOSIT_AMOUNT);
        assertEq(riskVault.totalAssets(), DEPOSIT_AMOUNT);
        assertEq(riskVault.totalShares(), DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testWithdraw() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Then withdraw
        vm.startPrank(user);
        uint256 shares = riskVault.withdraw(DEPOSIT_AMOUNT, user, user);
        
        // Verify withdrawal
        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(riskVault.balanceOf(user), 0);
        assertEq(riskVault.totalAssets(), 0);
        assertEq(riskVault.totalShares(), 0);
        
        vm.stopPrank();
    }

    function testRedeem() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Then redeem
        vm.startPrank(user);
        uint256 assets = riskVault.redeem(DEPOSIT_AMOUNT, user, user);
        
        // Verify redemption
        assertEq(assets, DEPOSIT_AMOUNT);
        assertEq(riskVault.balanceOf(user), 0);
        assertEq(riskVault.totalAssets(), 0);
        assertEq(riskVault.totalShares(), 0);
        
        vm.stopPrank();
    }

    function testConvertToShares() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Test conversion
        uint256 shares = riskVault.convertToShares(DEPOSIT_AMOUNT);
        assertEq(shares, DEPOSIT_AMOUNT);
        
        // Test with zero supply
        vm.startPrank(user);
        riskVault.redeem(DEPOSIT_AMOUNT, user, user);
        vm.stopPrank();
        
        shares = riskVault.convertToShares(DEPOSIT_AMOUNT);
        assertEq(shares, DEPOSIT_AMOUNT); // Should be 1:1 when supply is 0
    }

    function testConvertToAssets() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Test conversion
        uint256 assets = riskVault.convertToAssets(DEPOSIT_AMOUNT);
        assertEq(assets, DEPOSIT_AMOUNT);
        
        // Test with zero supply
        vm.startPrank(user);
        riskVault.redeem(DEPOSIT_AMOUNT, user, user);
        vm.stopPrank();
        
        assets = riskVault.convertToAssets(DEPOSIT_AMOUNT);
        assertEq(assets, DEPOSIT_AMOUNT); // Should be 1:1 when supply is 0
    }

    function testPreviewFunctions() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Test preview functions
        assertEq(riskVault.previewDeposit(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
        assertEq(riskVault.previewMint(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
        assertEq(riskVault.previewWithdraw(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
        assertEq(riskVault.previewRedeem(DEPOSIT_AMOUNT), DEPOSIT_AMOUNT);
    }

    function testMaxFunctions() public {
        // Test max functions
        assertEq(riskVault.maxDeposit(user), type(uint256).max);
        assertEq(riskVault.maxMint(user), type(uint256).max);
        assertEq(riskVault.maxWithdraw(user), 0);
        assertEq(riskVault.maxRedeem(user), 0);
        
        // After deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        assertEq(riskVault.maxWithdraw(user), DEPOSIT_AMOUNT);
        assertEq(riskVault.maxRedeem(user), DEPOSIT_AMOUNT);
    }

    function testAuthorizedDeposit() public {
        // Set up authorized depositor
        vm.prank(owner);
        riskVault.updateAuthorizedDepositor(authorizedDepositor, true);
        
        // Mint USDC to authorized depositor
        usdcToken.mint(authorizedDepositor, DEPOSIT_AMOUNT);
        
        vm.startPrank(authorizedDepositor);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        uint256 shares = riskVault.authorizedDeposit(DEPOSIT_AMOUNT);
        
        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(riskVault.balanceOf(authorizedDepositor), DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testAuthorizedDepositNotAuthorized() public {
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        vm.expectRevert("RiskVault: not authorized");
        riskVault.authorizedDeposit(DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testAuthorizedWithdraw() public {
        // Set up authorized depositor and deposit
        vm.prank(owner);
        riskVault.updateAuthorizedDepositor(authorizedDepositor, true);
        
        usdcToken.mint(authorizedDepositor, DEPOSIT_AMOUNT);
        
        vm.startPrank(authorizedDepositor);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.authorizedDeposit(DEPOSIT_AMOUNT);
        
        // Withdraw
        uint256 shares = riskVault.authorizedWithdraw(DEPOSIT_AMOUNT);
        
        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(riskVault.balanceOf(authorizedDepositor), 0);
        
        vm.stopPrank();
    }

    function testUpdateAuthorizedDepositor() public {
        vm.prank(owner);
        riskVault.updateAuthorizedDepositor(authorizedDepositor, true);
        
        assertTrue(riskVault.authorizedDepositors(authorizedDepositor));
        
        vm.prank(owner);
        riskVault.updateAuthorizedDepositor(authorizedDepositor, false);
        
        assertFalse(riskVault.authorizedDepositors(authorizedDepositor));
    }

    function testUpdateAuthorizedDepositorNotOwner() public {
        vm.expectRevert();
        riskVault.updateAuthorizedDepositor(authorizedDepositor, true);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        riskVault.pause();
        
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        
        vm.expectRevert("Pausable: paused");
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        
        vm.stopPrank();
        
        vm.prank(owner);
        riskVault.unpause();
        
        // Should work again
        vm.startPrank(user);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Mint some tokens to the vault
        usdcToken.mint(address(riskVault), 1000 * 10**6);
        
        uint256 initialBalance = usdcToken.balanceOf(owner);
        
        vm.prank(owner);
        riskVault.emergencyWithdraw(address(usdcToken), 500 * 10**6);
        
        uint256 finalBalance = usdcToken.balanceOf(owner);
        assertEq(finalBalance - initialBalance, 500 * 10**6);
    }

    function testEmergencyWithdrawNotOwner() public {
        vm.expectRevert();
        riskVault.emergencyWithdraw(address(usdcToken), 500 * 10**6);
    }

    function testWithdrawWithAllowance() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Approve another user to withdraw
        address spender = address(4);
        vm.prank(user);
        riskVault.approve(spender, DEPOSIT_AMOUNT);
        
        // Withdraw as spender
        vm.startPrank(spender);
        uint256 shares = riskVault.withdraw(DEPOSIT_AMOUNT, spender, user);
        
        assertEq(shares, DEPOSIT_AMOUNT);
        assertEq(riskVault.balanceOf(user), 0);
        
        vm.stopPrank();
    }

    function testWithdrawInsufficientAllowance() public {
        // First deposit
        vm.startPrank(user);
        usdcToken.approve(address(riskVault), DEPOSIT_AMOUNT);
        riskVault.deposit(DEPOSIT_AMOUNT, user);
        vm.stopPrank();
        
        // Approve another user with insufficient allowance
        address spender = address(4);
        vm.prank(user);
        riskVault.approve(spender, DEPOSIT_AMOUNT / 2);
        
        // Try to withdraw more than allowed
        vm.startPrank(spender);
        vm.expectRevert("RiskVault: insufficient allowance");
        riskVault.withdraw(DEPOSIT_AMOUNT, spender, user);
        
        vm.stopPrank();
    }
} 