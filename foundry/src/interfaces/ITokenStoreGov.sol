// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface ITokenStoreGov {
    /*//////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////*/
    event EmergencyReported(address indexed reporter);
    event EmergencyResolved(address indexed resolver);
    event TokenChanged(address indexed owner, address newToken, address oldToken);

    /*//////////////////////////////////////////////////////////////
                                TRANSACTIONS
    //////////////////////////////////////////////////////////////*/
    function reportEmergency() external;

    function resolveEmergency() external;

    function setToken(address _newToken) external;
}
