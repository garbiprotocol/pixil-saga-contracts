// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IRobot.sol";

/**
The Learning smart contract is a decentralized application built on the Ethereum blockchain.
Its purpose is to allow users to learn by interacting with their NFT robots.
Users can join the game by transferring their NFT robots to the contract, 
which will then start a learning process based on the robot's level. 
Users can upgrade their robots' level by paying a certain amount of token and 
waiting for a certain period of time, which will be used to improve their 
learning capabilities. The contract also rewards users with tokens for participating 
in the learning process.

Libraries
The contract uses several libraries provided by the OpenZeppelin framework, 
including SafeMath, Ownable, Pausable, IERC20, and IERC721Receiver. 
These libraries provide additional functionality and security to the contract.

State Variables
- IRobot and IERC20 are imported from the OpenZeppelin library 
and used to handle NFTs and ERC20 tokens.

- Learning is an Ownable, Pausable contract that implements the 
IERC721Receiver interface.

-DataUserLearn is a mapping that stores the LearnData of each user.
-
RobotJoinGameOfUser is a mapping that stores the RobotData of each user.

-PendingBlockUpgradeLevelRobotNFT is a mapping that stores the block number 
of the pending level upgrade for each robot NFT.

-DelayBlockRobotNFTOutGame is the number of blocks a user has to wait before 
they can remove their NFT from the game.

-PriceUpgradeLevelRobotNFT is a mapping that stores the price to upgrade each 
level of robot NFT.

-BlockUpgradeLevelRobotNFT is a mapping that stores the number of blocks 
needed to upgrade each level of robot NFT.

-MaxLevelOfRobotNFTInGame is the maximum level of robot NFT that can join the game.

-DelayBlockLearnNextTime is the number of blocks a user has to wait before 
they can start learning again.

-TotalBlockLearnEachTime is the total number of blocks a user needs to learn to earn rewards.

-RewardPerBlockOfLevel is a mapping that stores the reward for each block of 
learning based on the robot NFT level.

Structs
-LearnData: a struct that tracks a user's current learning progress

-Learning: a boolean that indicates whether the user is currently in a learning session

-StartBlockLearn: the block at which the user started the current learning session

-StopBlockLearn: the block at which the user stopped the current learning session

-PendingBlockLearn: the number of blocks remaining until the current learning session is complete

-RobotData: a struct that tracks a user's current NFT robot and the block at which it was added to the game

-BlockJoin: the block at which the NFT robot was added to the game

-TokenId: the ID of the NFT robot

-The contract includes several functions that allow users to join and exit the game, 
upgrade their NFTs, and start learning. The contract also includes several functions
that allow the owner to set the configuration parameters of the game.
 */

contract Learning is Ownable, IERC721Receiver, Pausable
{
    using SafeMath for uint256;

    IRobot public Robot;          // NFT learn
    IERC20 public TokenReward;     // Reward

    mapping(address => LearnData) public DataUserLearn;
    mapping(address => RobotData) public RobotJoinGameOfUser;
    mapping(uint256 => uint256) public PendingBlockUpgradeLevelRobotNFT;

    // config
    
    uint256 public DelayBlockRobotNFTOutGame;

    mapping(uint256 => uint256) public PriceUpgradeLevelRobotNFT; 
    mapping(uint256 => uint256) public BlockUpgradeLevelRobotNFT; 
    uint256 public MaxLevelOfRobotNFTInGame;
    uint256 public DelayBlockLearnNextTime;
    uint256 public TotalBlockLearnEachTime;

    mapping(uint256 => uint256) public RewardPerBlockOfLevel;

    event OnJoinGame(address user, uint256 tokenId);
    event OnOutGame(address user, uint256 tokenId);
    event OnUpgrateLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnConfirmUpgrateLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnStartLearn(address user, uint256 tokenId, uint256 level, uint256 startBlockLearn, uint256 pendingBlockLearn);
    event OnStopLearn(address user, uint256 tokenId, uint256 level, uint256 totalBlockLearnEachTime, uint256 stopBlockLearn);
    event OnBonusReward(address user, uint256 AmountTokenReward);

    struct LearnData
    {
        bool Learning;
        uint256 StartBlockLearn;
        uint256 StopBlockLearn;
        uint256 PendingBlockLearn;
    }

    struct RobotData
    {
        uint256 BlockJoin;
        uint256 TokenId;
    }

    constructor(
        IRobot robot,
        IERC20 tokenReward)
    {
        Robot = robot;
        TokenReward = tokenReward;
        
        // Test
        DelayBlockRobotNFTOutGame = 50;
        TotalBlockLearnEachTime = 30;       
        DelayBlockLearnNextTime = 10;

        PriceUpgradeLevelRobotNFT[0] = 0;
        PriceUpgradeLevelRobotNFT[1] = 100e18;
        PriceUpgradeLevelRobotNFT[2] = 200e18;
        PriceUpgradeLevelRobotNFT[3] = 300e18;

        BlockUpgradeLevelRobotNFT[0] = 0;
        BlockUpgradeLevelRobotNFT[1] = 100;
        BlockUpgradeLevelRobotNFT[2] = 200;
        BlockUpgradeLevelRobotNFT[3] = 300;

        RewardPerBlockOfLevel[0] = 5e17;
        RewardPerBlockOfLevel[1] = 1e18;
        RewardPerBlockOfLevel[2] = 2e18;
        RewardPerBlockOfLevel[3] = 3e18;

        MaxLevelOfRobotNFTInGame = 3;
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    // owner acction
    function SetPauseSystem() public onlyOwner 
    {
        _pause();
    }

    function SetEnableSystem() public onlyOwner
    {
        _unpause();
    }

    function SetDelayBlockRobotNFTOutGame(uint256 value) public onlyOwner 
    {
        DelayBlockRobotNFTOutGame = value;
    }

    function SetMaxLevelOfRobotNFTinGame(uint256 maxLevelOfRobotNFTinGame) public onlyOwner 
    {
        MaxLevelOfRobotNFTInGame = maxLevelOfRobotNFTinGame;
    }

    function SetTotalBlockLearnEachTime(uint256 totalBlockLearnEachTime) public onlyOwner
    {
        TotalBlockLearnEachTime = totalBlockLearnEachTime;
    }

    function SetRewardPerBlockOfLevel(uint256 level, uint256 value) public onlyOwner 
    {
        require(level <= MaxLevelOfRobotNFTInGame, "Invalid max level");
        RewardPerBlockOfLevel[level] = value;
    }

    function SetPriceUpgradeLevelRobotNFT(uint256 level, uint256 price) public onlyOwner
    {
        require(level <= MaxLevelOfRobotNFTInGame,  "Error SetPriceUpgradeLevelRobotNFT: Invalid level");
        PriceUpgradeLevelRobotNFT[level] = price;
    }

    function SetBlockUpgradeLevelRobotNFT(uint256 level, uint256 quantityBlock) public onlyOwner
    {
        require(level <= MaxLevelOfRobotNFTInGame,  "Error SetBlockUpgradeLevelRobotNFT: Invalid level");
        BlockUpgradeLevelRobotNFT[level] = quantityBlock;
    }

    /**
    This function allows a user to join the game by transferring their NFT robot to the game contract. 
    The function takes as input a tokenId, which identifies the NFT robot to be transferred. 
    The function checks that the NFT robot is owned by the user and removes it from the user's collection. 
    It then stores information about the user's participation in the game, 
    including the block number at which the user joined and the tokenId of the robot. 
    Finally, the function emits an event to notify that the user has joined the game.    
     */
    function LetRobotNFTJoinTheGame(uint256 tokenId) public whenNotPaused
    {
        address user = msg.sender;
        require(Robot.ownerOf(tokenId) == user, "Error JoinGame: Invalid token");
        require(removeRobot(user) == true, "Error JoinGame: remove");

        Robot.safeTransferFrom(user, address(this), tokenId);

        RobotData storage robotData = RobotJoinGameOfUser[user];
        robotData.BlockJoin = block.number;
        robotData.TokenId = tokenId;

        emit OnJoinGame(msg.sender, tokenId);
    }

    /**
    This function allows a user to leave the game by transferring their NFT robot back to their collection. 
    The function checks that the user has joined the game and removes information about 
    the user's participation in the game. If the user was learning, it stops the learning process. 
    Finally, the function removes the robot from the game contract and emits an event to notify that 
    the user has left the game.
     */

    function LetRobotNFTOutOfTheGame() public 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        require(robotData.TokenId != 0, "Error OutGame: Haven't joined the game");

        LearnData memory data = DataUserLearn[user]; 
        if (data.StartBlockLearn > data.StopBlockLearn) 
        {
            LetRobotNFTStopLearn();
        }
        require(removeRobot(msg.sender) == true, "Error OutGame: removeRobot");
    }

    /**
    This function allows a user to upgrade the level of their NFT robot by paying a certain amount of tokens. 
    The function checks that the user has joined the game and that the level of the robot
    is lower than the maximum allowed level. It also checks that the user has enough tokens to pay for the upgrade. 
    If all checks pass, the function transfers the tokens from the user to the game contract and
    sets a pending block number for the upgrade. Finally, the function emits an event to notify 
    that the user has initiated an upgrade.
     */
    function UpgradeLevelRobot() public whenNotPaused
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error UpgrateLevelRobot: Invalid tokenId");

        uint256 level = Robot.Level(tokenId);
        require(level < MaxLevelOfRobotNFTInGame, "Error UpgrateLevelRobot: Invalid level");
        require(TokenReward.balanceOf(user) >= PriceUpgradeLevelRobotNFT[level.add(1)], "Error UpgrateLevelRobot: Invalid balance");
        
        TokenReward.transferFrom(user, address(this), PriceUpgradeLevelRobotNFT[level.add(1)]);

        PendingBlockUpgradeLevelRobotNFT[tokenId] = block.number.add(BlockUpgradeLevelRobotNFT[level.add(1)]);

        emit OnUpgrateLevelRobot(user, tokenId, level);
    }

    /**
    This function confirms the upgrade of a user's NFT robot. 
    The function checks that the upgrade has been initiated and that the pending block number 
    for the upgrade has passed. It then upgrades the level of the robot and removes the pending block number. 
    Finally, the function emits an event to notify that the upgrade has been confirmed. 
    */
    function ConfirmUpgrateLevelRobot() public whenNotPaused
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(PendingBlockUpgradeLevelRobotNFT[tokenId] > 0, "Error ConfirmUpgrateLevelRobot: Validate");
        require(block.number >= PendingBlockUpgradeLevelRobotNFT[tokenId], "Error ConfirmUpgrateLevelRobot: Time out");
        PendingBlockUpgradeLevelRobotNFT[tokenId] = 0;
        Robot.UpgradeLevel(tokenId);

        emit OnConfirmUpgrateLevelRobot(user, tokenId, Robot.Level(tokenId));
    }

    /**
    This function allows a user to start the learning process for their NFT robot.
    The function checks that the user has joined the game and that the robot is not currently learning.
    It then sets the start block number for the learning process and sets the learning flag to true. 
    Finally, the function emits an event to notify that the learning process has started. 
    */
    function ForRobotNFTToLearn() public whenNotPaused 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error StartLearn: Invalid tokenId");

        LearnData storage data = DataUserLearn[user]; 
        require(data.StartBlockLearn < block.number, "Error StartLearn: Time out");
        require(data.Learning == false, "Error StartLearn: Learning");

        if(data.PendingBlockLearn == 0)
        {
            data.PendingBlockLearn = TotalBlockLearnEachTime;
        }

        data.StartBlockLearn = block.number;
        data.Learning = true;

        emit OnStartLearn(user, tokenId, Robot.Level(tokenId), data.StartBlockLearn, data.PendingBlockLearn);
    }


    /*
    This function allows a user to stop the learning process for their NFT robot. 
    The function checks that the robot is currently learning and calculates the number of blocks
    that have passed since the start of the learning process. 
    If the required number of blocks has been reached, 
    it sets the start block number for the next learning process and sets the pending block number to 0. 
    Otherwise, it updates the pending block number. 
    Finally, the function calculates the bonus tokens that the user will receive and emits an event to notify 
    that the learning process has stopped.
     */
    function LetRobotNFTStopLearn() public whenNotPaused
    {
        address user = msg.sender;

        LearnData storage data = DataUserLearn[user]; 
        require(data.Learning == true, "Error StopLearn: Not learning");

        uint256 totalBlockLearnEachTimeedOfUser = block.number.sub(data.StartBlockLearn);
        if(totalBlockLearnEachTimeedOfUser >= data.PendingBlockLearn)
        {
            totalBlockLearnEachTimeedOfUser = data.PendingBlockLearn;

            data.StartBlockLearn = block.number.add(DelayBlockLearnNextTime);
            data.PendingBlockLearn = 0;
        }
        else
        {
            data.PendingBlockLearn = data.PendingBlockLearn.sub(totalBlockLearnEachTimeedOfUser);
        }
        data.Learning = false;
        data.StopBlockLearn = block.number;

        DoBonusToken(user, totalBlockLearnEachTimeedOfUser);
    }

    function GetData(address user) public view returns(
        uint256 cyberCreditBalance,
        uint256 tokenId,
        uint256 levelRobotJoinGameOfUser,
        uint256 blockNumber,
        bool learning,
        uint256 startBlockLearn,
        uint256 stopBlockLearn,
        uint256 pendingBlockLearn,
        uint256 rewardPerDay,
        uint256 pendingBlockUpgradeLevelRobotNFT
    )
    {
        cyberCreditBalance = TokenReward.balanceOf(user);
        RobotData memory robotData = RobotJoinGameOfUser[user];
        tokenId = robotData.TokenId;
        levelRobotJoinGameOfUser = Robot.Level(tokenId);
        blockNumber = block.number;

        LearnData memory data = DataUserLearn[user];
        learning = data.Learning;
        startBlockLearn = data.StartBlockLearn;
        pendingBlockLearn = data.PendingBlockLearn;
        stopBlockLearn = data.StopBlockLearn;

        if(pendingBlockLearn != 0) 
        {
            uint256 totalBlockLearnEachTimeed = TotalBlockLearnEachTime.sub(pendingBlockLearn);
            uint256 totalBlockLearnEachTimeing = blockNumber.sub(startBlockLearn);

            rewardPerDay = (startBlockLearn < stopBlockLearn) ?
                totalBlockLearnEachTimeed.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) :
                    ((totalBlockLearnEachTimeed.add(totalBlockLearnEachTimeing))
                        .mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) <
                        TotalBlockLearnEachTime.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser])) ? 
                            (totalBlockLearnEachTimeed.add(totalBlockLearnEachTimeing))
                            .mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) :
                                TotalBlockLearnEachTime.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]);
        }

        pendingBlockUpgradeLevelRobotNFT  = PendingBlockUpgradeLevelRobotNFT[tokenId];
        
    }

    function GetConfigSystem() public view returns(
        uint256 maxLevelOfRobotNFTinGame,
        uint256[] memory priceUpgradeLevelRobotNFTLevel,
        uint256 totalBlockLearnEachTime,
        uint256[] memory rewardPerBlockOfLevel,
        uint256[] memory blockUpgradeLevelRobotNFT
    )
    {
        maxLevelOfRobotNFTinGame = MaxLevelOfRobotNFTInGame;

        priceUpgradeLevelRobotNFTLevel = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 1; level <= maxLevelOfRobotNFTinGame; level++)
        {
            priceUpgradeLevelRobotNFTLevel[level] = PriceUpgradeLevelRobotNFT[level]; 
        }

        totalBlockLearnEachTime = TotalBlockLearnEachTime;

        rewardPerBlockOfLevel = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 0; level <= maxLevelOfRobotNFTinGame; level++)
        {
            rewardPerBlockOfLevel[level] = RewardPerBlockOfLevel[level];
        }

        blockUpgradeLevelRobotNFT = new uint256[](maxLevelOfRobotNFTinGame.add(1));
        for(uint level = 0; level <= maxLevelOfRobotNFTinGame; level++)
        {
            blockUpgradeLevelRobotNFT[level] = BlockUpgradeLevelRobotNFT[level];
        }
    }

    /**
    This function calculates the bonus token reward for the user based on the number of blocks learned 
    by the user and transfers it to the user's address. 
    The bonus token reward is calculated based on the level of the user's robot and the reward per block for that level. 
    If the contract balance of TokenReward is less than the bonus token reward, 
    then it transfers the entire balance to the user. After transferring the bonus tokens, 
    it emits an event OnBonusReward with the user's address and the bonus token reward as parameters.
     */
    function DoBonusToken(address user, uint256 totalBlockLearnEachTimeed) private 
    {
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        uint256 level = Robot.Level(tokenId);
        uint256 rewardPerBlock = RewardPerBlockOfLevel[level];
        if(TokenReward.balanceOf(address(this)) >= totalBlockLearnEachTimeed.mul(rewardPerBlock))
        {
            TokenReward.transfer(user, totalBlockLearnEachTimeed.mul(rewardPerBlock));

            emit OnBonusReward(user, totalBlockLearnEachTimeed.mul(rewardPerBlock));
        }
        else
        {
            TokenReward.transfer(user, TokenReward.balanceOf(address(this)));

            emit OnBonusReward(user, TokenReward.balanceOf(address(this)));
        }
    }  

    /** 
    This function removes the robot associated with the user and transfers it to the user's address. 
    The robot can be removed only if the time since the robot was joined in the game is greater 
    than DelayBlockRobotNFTOutGame. If the robot is successfully removed, 
    it sets the token ID of the robot to 0 and emits an event OnOutGame 
    with the sender's address and the token ID as parameters. 
    The function returns true if the robot is successfully removed, else it returns false.
    */
    function removeRobot(address user) private returns(bool)
    {
        RobotData storage robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;

        if(tokenId == 0) return true;
        
        require(robotData.BlockJoin.add(DelayBlockRobotNFTOutGame) <= block.number, "Error removeRobot: Time out");
        Robot.safeTransferFrom(address(this), user, tokenId);

        robotData.TokenId = 0;

        emit OnOutGame(msg.sender, tokenId);
        return true;
    }
}