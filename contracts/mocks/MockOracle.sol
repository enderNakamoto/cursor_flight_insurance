// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IOracle.sol";

/**
 * @dev Mock Oracle for testing flight data
 */
contract MockOracle is IOracle {
    mapping(bytes32 => FlightData) private flightData;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "MockOracle: caller is not the owner");
        _;
    }

    function getFlightData(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        override 
        returns (FlightData memory) {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, departureTime));
        return flightData[key];
    }

    function updateFlightData(
        string calldata flightNumber,
        uint256 scheduledDepartureTime,
        uint256 actualDepartureTime,
        bool isCancelled
    ) external override onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, scheduledDepartureTime));
        
        uint256 delayHours = 0;
        bool isDelayed = false;
        
        if (!isCancelled && actualDepartureTime > scheduledDepartureTime) {
            delayHours = (actualDepartureTime - scheduledDepartureTime) / 1 hours;
            isDelayed = delayHours >= 6;
        }

        flightData[key] = FlightData({
            flightNumber: flightNumber,
            scheduledDepartureTime: scheduledDepartureTime,
            actualDepartureTime: actualDepartureTime,
            delayHours: delayHours,
            isDelayed: isDelayed,
            isCancelled: isCancelled,
            lastUpdated: block.timestamp
        });

        emit FlightDataUpdated(
            flightNumber,
            scheduledDepartureTime,
            actualDepartureTime,
            delayHours,
            isDelayed
        );
    }

    function isFlightDelayed(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        override 
        returns (bool, uint256) {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, departureTime));
        FlightData memory data = flightData[key];
        return (data.isDelayed, data.delayHours);
    }

    function getDelayHours(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        override 
        returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(flightNumber, departureTime));
        return flightData[key].delayHours;
    }
} 