// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IERC4626.sol";

/**
 * @title RiskVault
 * @dev ERC4626 vault for capital providers to earn insurance premiums
 */
contract RiskVault is IERC4626, ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // State variables
    IERC20 public immutable assetToken;
    uint256 public totalAssets_;
    uint256 public totalShares_;
    
    // Access control
    mapping(address => bool) public authorizedDepositors;
    
    // Events
    event AuthorizedDepositorUpdated(address indexed depositor, bool authorized);
    event EmergencyWithdraw(address indexed token, uint256 amount);

    // Modifiers
    modifier onlyAuthorizedDepositor() {
        require(authorizedDepositors[msg.sender] || msg.sender == owner(), "RiskVault: not authorized");
        _;
    }

    /**
     * @dev Constructor
     * @param _asset Asset token address
     * @param _name Vault name
     * @param _symbol Vault symbol
     */
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_asset != address(0), "RiskVault: invalid asset address");
        assetToken = IERC20(_asset);
    }

    /**
     * @dev Returns the underlying asset token
     */
    function asset() external view override returns (address) {
        return address(assetToken);
    }

    /**
     * @dev Returns the total assets in the vault
     */
    function totalAssets() public view override returns (uint256) {
        return totalAssets_;
    }

    /**
     * @dev Returns the total shares in the vault
     */
    function totalShares() public view returns (uint256) {
        return totalShares_;
    }

    /**
     * @dev Convert assets to shares
     */
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalShares();
        if (supply == 0) {
            return assets;
        }
        return assets.mulDiv(supply, totalAssets(), Math.Rounding.Floor);
    }

    /**
     * @dev Convert shares to assets
     */
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalShares();
        if (supply == 0) {
            return shares;
        }
        return shares.mulDiv(totalAssets(), supply, Math.Rounding.Floor);
    }

    /**
     * @dev Preview deposit
     */
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @dev Preview mint
     */
    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalShares();
        if (supply == 0) {
            return shares;
        }
        return shares.mulDiv(totalAssets(), supply, Math.Rounding.Ceil);
    }

    /**
     * @dev Preview withdraw
     */
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalShares();
        if (supply == 0) {
            return 0;
        }
        return assets.mulDiv(supply, totalAssets(), Math.Rounding.Ceil);
    }

    /**
     * @dev Preview redeem
     */
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    /**
     * @dev Max deposit
     */
    function maxDeposit(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Max mint
     */
    function maxMint(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Max withdraw
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /**
     * @dev Max redeem
     */
    function maxRedeem(address owner) public view override returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @dev Deposit assets and receive shares
     */
    function deposit(uint256 assets, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        require(assets > 0, "RiskVault: cannot deposit 0");
        require(receiver != address(0), "RiskVault: invalid receiver");

        uint256 shares = previewDeposit(assets);
        require(shares > 0, "RiskVault: zero shares");

        // Transfer assets from caller
        assetToken.safeTransferFrom(msg.sender, address(this), assets);

        // Mint shares to receiver
        _mint(receiver, shares);

        // Update state
        totalAssets_ += assets;
        totalShares_ += shares;

        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /**
     * @dev Mint shares for assets
     */
    function mint(uint256 shares, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        require(shares > 0, "RiskVault: cannot mint 0");
        require(receiver != address(0), "RiskVault: invalid receiver");

        uint256 assets = previewMint(shares);
        require(assets > 0, "RiskVault: zero assets");

        // Transfer assets from caller
        assetToken.safeTransferFrom(msg.sender, address(this), assets);

        // Mint shares to receiver
        _mint(receiver, shares);

        // Update state
        totalAssets_ += assets;
        totalShares_ += shares;

        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    /**
     * @dev Withdraw assets for shares
     */
    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused nonReentrant returns (uint256) {
        require(assets > 0, "RiskVault: cannot withdraw 0");
        require(receiver != address(0), "RiskVault: invalid receiver");

        uint256 shares = previewWithdraw(assets);
        require(shares > 0, "RiskVault: zero shares");

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(shares <= allowed, "RiskVault: insufficient allowance");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        // Burn shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        assetToken.safeTransfer(receiver, assets);

        // Update state
        totalAssets_ -= assets;
        totalShares_ -= shares;

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @dev Redeem shares for assets
     */
    function redeem(uint256 shares, address receiver, address owner) public override whenNotPaused nonReentrant returns (uint256) {
        require(shares > 0, "RiskVault: cannot redeem 0");
        require(receiver != address(0), "RiskVault: invalid receiver");

        uint256 assets = previewRedeem(shares);
        require(assets > 0, "RiskVault: zero assets");

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(shares <= allowed, "RiskVault: insufficient allowance");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        // Burn shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        assetToken.safeTransfer(receiver, assets);

        // Update state
        totalAssets_ -= assets;
        totalShares_ -= shares;

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Authorized deposit (for insurance controller)
     */
    function authorizedDeposit(uint256 assets) external onlyAuthorizedDepositor returns (uint256) {
        require(assets > 0, "RiskVault: cannot deposit 0");

        uint256 shares = previewDeposit(assets);
        require(shares > 0, "RiskVault: zero shares");

        // Mint shares to insurance controller
        _mint(msg.sender, shares);

        // Update state
        totalAssets_ += assets;
        totalShares_ += shares;

        emit Deposit(msg.sender, msg.sender, assets, shares);

        return shares;
    }

    /**
     * @dev Authorized withdraw (for insurance controller)
     */
    function authorizedWithdraw(uint256 assets) external onlyAuthorizedDepositor returns (uint256) {
        require(assets > 0, "RiskVault: cannot withdraw 0");

        uint256 shares = previewWithdraw(assets);
        require(shares > 0, "RiskVault: zero shares");

        // Burn shares from insurance controller
        _burn(msg.sender, shares);

        // Update state
        totalAssets_ -= assets;
        totalShares_ -= shares;

        emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);

        return shares;
    }

    /**
     * @dev Update authorized depositor status
     */
    function updateAuthorizedDepositor(address depositor, bool authorized) external onlyOwner {
        authorizedDepositors[depositor] = authorized;
        emit AuthorizedDepositorUpdated(depositor, authorized);
    }

    /**
     * @dev Pause the vault
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the vault
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdraw(token, amount);
    }

    /**
     * @dev Override decimals to match asset
     */
    function decimals() public view virtual override returns (uint8) {
        return IERC20Metadata(address(assetToken)).decimals();
    }
} 