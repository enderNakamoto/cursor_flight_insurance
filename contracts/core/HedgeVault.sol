// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title HedgeVault
 * @dev Per-flight vault for insurance policy backing
 */
contract HedgeVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public immutable usdcToken;
    string public flightNumber;
    uint256 public departureTime;
    uint256 public requiredCapital;
    uint256 public depositedCapital;
    bool public isActive;
    bool public isClaimed;
    
    // Access control
    mapping(address => bool) public authorizedOperators;
    
    // Events
    event CapitalDeposited(address indexed depositor, uint256 amount);
    event CapitalWithdrawn(address indexed withdrawer, uint256 amount);
    event ClaimProcessed(uint256 indexed payout, address indexed policyholder);
    event VaultDeactivated();
    event AuthorizedOperatorUpdated(address indexed operator, bool authorized);

    // Modifiers
    modifier onlyAuthorizedOperator() {
        require(authorizedOperators[msg.sender] || msg.sender == owner(), "HedgeVault: not authorized");
        _;
    }

    modifier onlyActive() {
        require(isActive, "HedgeVault: vault is not active");
        _;
    }

    modifier onlyNotClaimed() {
        require(!isClaimed, "HedgeVault: vault already claimed");
        _;
    }

    /**
     * @dev Constructor
     * @param _usdcToken USDC token address
     * @param _flightNumber Flight number
     * @param _departureTime Scheduled departure time
     * @param _requiredCapital Required capital for this flight
     */
    constructor(
        address _usdcToken,
        string memory _flightNumber,
        uint256 _departureTime,
        uint256 _requiredCapital
    ) Ownable(msg.sender) {
        require(_usdcToken != address(0), "HedgeVault: invalid USDC address");
        require(bytes(_flightNumber).length > 0, "HedgeVault: flight number cannot be empty");
        require(_departureTime > block.timestamp, "HedgeVault: departure time must be in the future");
        require(_requiredCapital > 0, "HedgeVault: required capital must be greater than 0");

        usdcToken = IERC20(_usdcToken);
        flightNumber = _flightNumber;
        departureTime = _departureTime;
        requiredCapital = _requiredCapital;
        isActive = true;
        isClaimed = false;
    }

    /**
     * @dev Deposit capital to the vault
     * @param amount Amount to deposit
     */
    function depositCapital(uint256 amount) external onlyAuthorizedOperator onlyActive onlyNotClaimed {
        require(amount > 0, "HedgeVault: cannot deposit 0");
        require(depositedCapital + amount <= requiredCapital, "HedgeVault: exceeds required capital");

        usdcToken.safeTransferFrom(msg.sender, address(this), amount);
        depositedCapital += amount;

        emit CapitalDeposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw capital from the vault (only if not claimed)
     * @param amount Amount to withdraw
     */
    function withdrawCapital(uint256 amount) external onlyAuthorizedOperator onlyActive onlyNotClaimed {
        require(amount > 0, "HedgeVault: cannot withdraw 0");
        require(amount <= depositedCapital, "HedgeVault: insufficient capital");

        depositedCapital -= amount;
        usdcToken.safeTransfer(msg.sender, amount);

        emit CapitalWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Process claim payout
     * @param policyholder Policyholder address
     * @param payoutAmount Payout amount
     */
    function processClaim(address policyholder, uint256 payoutAmount) external onlyAuthorizedOperator onlyActive onlyNotClaimed {
        require(policyholder != address(0), "HedgeVault: invalid policyholder");
        require(payoutAmount > 0, "HedgeVault: invalid payout amount");
        require(payoutAmount <= depositedCapital, "HedgeVault: insufficient capital for payout");

        isClaimed = true;
        isActive = false;

        usdcToken.safeTransfer(policyholder, payoutAmount);
        depositedCapital -= payoutAmount;

        emit ClaimProcessed(payoutAmount, policyholder);
    }

    /**
     * @dev Deactivate vault after flight time + expiration
     */
    function deactivateVault() external onlyAuthorizedOperator onlyActive {
        require(
            block.timestamp > departureTime + (24 hours),
            "HedgeVault: flight not yet expired"
        );

        isActive = false;
        emit VaultDeactivated();
    }

    /**
     * @dev Get vault status
     * @return _isActive Whether vault is active
     * @return _isClaimed Whether vault has been claimed
     * @return _depositedCapital Current deposited capital
     * @return _requiredCapital Required capital
     */
    function getVaultStatus() external view returns (
        bool _isActive,
        bool _isClaimed,
        uint256 _depositedCapital,
        uint256 _requiredCapital
    ) {
        return (isActive, isClaimed, depositedCapital, requiredCapital);
    }

    /**
     * @dev Check if vault is fully funded
     * @return True if vault has required capital
     */
    function isFullyFunded() external view returns (bool) {
        return depositedCapital >= requiredCapital;
    }

    /**
     * @dev Get remaining capital needed
     * @return Remaining capital needed
     */
    function getRemainingCapitalNeeded() external view returns (uint256) {
        if (depositedCapital >= requiredCapital) {
            return 0;
        }
        return requiredCapital - depositedCapital;
    }

    /**
     * @dev Update authorized operator status
     * @param operator Operator address
     * @param authorized Whether operator is authorized
     */
    function updateAuthorizedOperator(address operator, bool authorized) external onlyOwner {
        authorizedOperators[operator] = authorized;
        emit AuthorizedOperatorUpdated(operator, authorized);
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
     * @dev Emergency withdraw (owner only)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    /**
     * @dev Get vault information
     * @return _flightNumber Flight number
     * @return _departureTime Departure time
     * @return _requiredCapital Required capital
     * @return _depositedCapital Deposited capital
     */
    function getVaultInfo() external view returns (
        string memory _flightNumber,
        uint256 _departureTime,
        uint256 _requiredCapital,
        uint256 _depositedCapital
    ) {
        return (flightNumber, departureTime, requiredCapital, depositedCapital);
    }
} 