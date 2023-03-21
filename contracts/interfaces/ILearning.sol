// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface ILearning
{
    function ForRobotNFTStopLearn() external;

    function DataUserLearn(address user) external pure returns (
        bool Learning, //a boolean that indicates whether the user is currently in a learning session             
        uint256 StartBlockLearn, //the block at which the user started the current learning session
        uint256 StopBlockLearn, //the block at which the user stopped the current learning session
        uint256 PendingBlockLearn //the number of blocks remaining until the current learning session is complete
    );
}