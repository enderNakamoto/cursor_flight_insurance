// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IFlightInsurance.sol";
import "../interfaces/IERC4626.sol";
import "../interfaces/IOracle.sol";

/**
 * @title FlightInsurance
 * @dev Main controller contract for flight delay insurance protocol
 */
contract FlightInsurance is IFlightInsurance, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant PREMIUM_AMOUNT = 50 * 10**6; // 50 USDC (6 decimals)
    uint256 public constant PAYOUT_AMOUNT = 200 * 10**6; // 200 USDC (6 decimals)
    uint256 public constant DELAY_THRESHOLD_HOURS = 6;
    uint256 public constant POLICY_EXPIRATION_HOURS = 24;
    uint256 public constant CAPITAL_RATIO = 4; // 4:1 ratio

    // State variables
    IERC20 public immutable usdcToken;
    IERC4626 public immutable riskVault;
    IOracle public oracle;
    
    uint256 public policyCounter;
    uint256 public totalPremiums;
    uint256 public totalPayouts;
    
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyholderPolicies;
    mapping(string => mapping(uint256 => uint256)) public flightPolicies; // flightNumber => departureTime => policyId
    
    // Events
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    event ClaimProcessed(uint256 indexed policyId, address indexed policyholder, uint256 payout, uint256 delayHours);

    // Modifiers
    modifier onlyOracle() {
        require(msg.sender == address(oracle), "FlightInsurance: caller is not oracle");
        _;
    }

    modifier validPolicy(uint256 policyId) {
        require(policyId > 0 && policyId <= policyCounter, "FlightInsurance: invalid policy ID");
        _;
    }

    /**
     * @dev Constructor
     * @param _usdcToken USDC token address
     * @param _riskVault Risk vault address
     * @param _oracle Oracle address
     */
    constructor(
        address _usdcToken,
        address _riskVault,
        address _oracle
    ) Ownable(msg.sender) {
        require(_usdcToken != address(0), "FlightInsurance: invalid USDC address");
        require(_riskVault != address(0), "FlightInsurance: invalid risk vault address");
        require(_oracle != address(0), "FlightInsurance: invalid oracle address");
        
        usdcToken = IERC20(_usdcToken);
        riskVault = IERC4626(_riskVault);
        oracle = IOracle(_oracle);
    }

    /**
     * @dev Create a new insurance policy
     * @param flightNumber Flight number
     * @param departureTime Scheduled departure time
     * @return policyId The ID of the created policy
     */
    function createPolicy(
        string calldata flightNumber,
        uint256 departureTime
    ) external override whenNotPaused nonReentrant returns (uint256 policyId) {
        require(bytes(flightNumber).length > 0, "FlightInsurance: flight number cannot be empty");
        require(departureTime > block.timestamp, "FlightInsurance: departure time must be in the future");
        require(flightPolicies[flightNumber][departureTime] == 0, "FlightInsurance: policy already exists for this flight");
        
        // Check capital ratio requirement
        require(
            riskVault.totalAssets() >= (policyCounter + 1) * PAYOUT_AMOUNT * CAPITAL_RATIO,
            "FlightInsurance: insufficient capital ratio"
        );

        // Transfer premium from user
        usdcToken.safeTransferFrom(msg.sender, address(this), PREMIUM_AMOUNT);
        
        // Deposit premium to risk vault
        usdcToken.approve(address(riskVault), PREMIUM_AMOUNT);
        riskVault.deposit(PREMIUM_AMOUNT, address(this));

        // Create policy
        policyCounter++;
        policyId = policyCounter;
        
        policies[policyId] = Policy({
            policyholder: msg.sender,
            flightNumber: flightNumber,
            departureTime: departureTime,
            premium: PREMIUM_AMOUNT,
            payout: PAYOUT_AMOUNT,
            isActive: true,
            isClaimed: false,
            createdAt: block.timestamp
        });

        policyholderPolicies[msg.sender].push(policyId);
        flightPolicies[flightNumber][departureTime] = policyId;
        
        totalPremiums += PREMIUM_AMOUNT;

        emit PolicyCreated(
            policyId,
            msg.sender,
            flightNumber,
            departureTime,
            PREMIUM_AMOUNT,
            PAYOUT_AMOUNT
        );

        return policyId;
    }

    /**
     * @dev Get policy details
     * @param policyId Policy ID
     * @return Policy details
     */
    function getPolicy(uint256 policyId) external view override validPolicy(policyId) returns (Policy memory) {
        return policies[policyId];
    }

    /**
     * @dev Get all policies for a policyholder
     * @param policyholder Policyholder address
     * @return Array of policy IDs
     */
    function getPolicyholderPolicies(address policyholder) external view override returns (uint256[] memory) {
        return policyholderPolicies[policyholder];
    }

    /**
     * @dev Settle a claim for a policy
     * @param policyId Policy ID
     * @param delayHours Delay in hours
     */
    function settleClaim(uint256 policyId, uint256 delayHours) external override onlyOracle validPolicy(policyId) {
        Policy storage policy = policies[policyId];
        require(policy.isActive, "FlightInsurance: policy is not active");
        require(!policy.isClaimed, "FlightInsurance: policy already claimed");
        require(delayHours >= DELAY_THRESHOLD_HOURS, "FlightInsurance: delay below threshold");

        policy.isClaimed = true;
        policy.isActive = false;

        // Transfer payout to policyholder
        usdcToken.safeTransfer(policy.policyholder, policy.payout);
        
        totalPayouts += policy.payout;

        emit ClaimSettled(policyId, policy.policyholder, policy.payout, delayHours);
    }

    /**
     * @dev Expire a policy after flight time + expiration period
     * @param policyId Policy ID
     */
    function expirePolicy(uint256 policyId) external override validPolicy(policyId) {
        Policy storage policy = policies[policyId];
        require(policy.isActive, "FlightInsurance: policy is not active");
        require(
            block.timestamp > policy.departureTime + (POLICY_EXPIRATION_HOURS * 1 hours),
            "FlightInsurance: policy not yet expired"
        );

        policy.isActive = false;

        emit PolicyExpired(policyId, policy.policyholder);
    }

    /**
     * @dev Get all active policies
     * @return Array of active policy IDs
     */
    function getActivePolicies() external view override returns (uint256[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= policyCounter; i++) {
            if (policies[i].isActive) {
                activeCount++;
            }
        }

        uint256[] memory activePolicies = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= policyCounter; i++) {
            if (policies[i].isActive) {
                activePolicies[index] = i;
                index++;
            }
        }

        return activePolicies;
    }

    /**
     * @dev Get total number of policies
     * @return Total policy count
     */
    function getTotalPolicies() external view override returns (uint256) {
        return policyCounter;
    }

    /**
     * @dev Get total premiums collected
     * @return Total premiums
     */
    function getTotalPremiums() external view override returns (uint256) {
        return totalPremiums;
    }

    /**
     * @dev Get total payouts made
     * @return Total payouts
     */
    function getTotalPayouts() external view override returns (uint256) {
        return totalPayouts;
    }

    /**
     * @dev Update oracle address (owner only)
     * @param newOracle New oracle address
     */
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "FlightInsurance: invalid oracle address");
        address oldOracle = address(oracle);
        oracle = IOracle(newOracle);
        emit OracleUpdated(oldOracle, newOracle);
    }

    /**
     * @dev Pause the contract (owner only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdraw function (owner only)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
} 