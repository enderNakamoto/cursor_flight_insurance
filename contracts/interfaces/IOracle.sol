// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Interface for Flight Oracle
 */
interface IOracle {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event FlightDataUpdated(
        string indexed flightNumber,
        uint256 indexed departureTime,
        uint256 actualDepartureTime,
        uint256 delayHours,
        bool isDelayed
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct FlightData {
        string flightNumber;
        uint256 scheduledDepartureTime;
        uint256 actualDepartureTime;
        uint256 delayHours;
        bool isDelayed;
        bool isCancelled;
        uint256 lastUpdated;
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getFlightData(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        returns (FlightData memory);

    function updateFlightData(
        string calldata flightNumber,
        uint256 scheduledDepartureTime,
        uint256 actualDepartureTime,
        bool isCancelled
    ) external;

    function isFlightDelayed(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        returns (bool, uint256);

    function getDelayHours(string calldata flightNumber, uint256 departureTime) 
        external 
        view 
        returns (uint256);
} 