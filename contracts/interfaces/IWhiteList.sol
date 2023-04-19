// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhiteList 
{
    function whitelisted(address _address) external view returns (bool);
}