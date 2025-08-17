// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Interface for Flight Insurance Controller
 */
interface IFlightInsurance {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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

    event PolicyExpired(uint256 indexed policyId, address indexed policyholder);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Policy {
        address policyholder;
        string flightNumber;
        uint256 departureTime;
        uint256 premium;
        uint256 payout;
        bool isActive;
        bool isClaimed;
        uint256 createdAt;
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function createPolicy(
        string calldata flightNumber,
        uint256 departureTime
    ) external returns (uint256 policyId);

    function getPolicy(uint256 policyId) external view returns (Policy memory);

    function getPolicyholderPolicies(address policyholder) external view returns (uint256[] memory);

    function settleClaim(uint256 policyId, uint256 delayHours) external;

    function expirePolicy(uint256 policyId) external;

    function getActivePolicies() external view returns (uint256[] memory);

    function getTotalPolicies() external view returns (uint256);

    function getTotalPremiums() external view returns (uint256);

    function getTotalPayouts() external view returns (uint256);
} 