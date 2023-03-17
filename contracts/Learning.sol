// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IRobot.sol";

    /**
    This contract allows users to learn by using their NFT robots. 
    Users can join the game by transferring their robots to the contract, 
    and the contract will start a learning process based on the robot's level. 
    Users can upgrade their robots' level by paying tokens and waiting for a period of time. 
    The contract rewards users with tokens for participating in the learning process.
    */

contract Learning is Ownable, IERC721Receiver, Pausable
{
    using SafeMath for uint256;

    IRobot public Robot;          // NFT learn
    IERC20 public TokenReward;     // Reward

    // stores the LearnData of each user.
    mapping(address => LearnData) public DataUserLearn;

    // stores the RobotData of each user.
    mapping(address => RobotData) public RobotJoinGameOfUser;

    //stores the block number of the pending level upgrade for each robot NFT.
    mapping(uint256 => uint256) public PendingBlockUpgradeLevelRobotNFT;

    // config
    
    //number of blocks a user has to wait before they can remove their NFT from the game.
    uint256 public DelayBlockRobotNFTOutGame;

    //stores the price to upgrade each level of robot NFT.
    mapping(uint256 => uint256) public PriceUpgradeLevelRobotNFT; 

    // stores the number of blocks needed to upgrade each level of robot NFT.
    mapping(uint256 => uint256) public BlockUpgradeLevelRobotNFT; 

    //stores the reward for each block of learning based on the robot NFT level.
    mapping(uint256 => uint256) public RewardPerBlockOfLevel;

    // the maximum level of robot NFT that can join the game.
    uint256 public MaxLevelOfRobotNFTInGame;

    //the number of blocks a user has to wait before they can start learning again.
    uint256 public DelayBlockLearnNextTime;

    //the total number of blocks a user needs to learn to earn rewards.
    uint256 public TotalBlockLearnEachTime;

    // Event action
    event OnJoinGame(address user, uint256 tokenId);
    event OnOutGame(address user, uint256 tokenId);
    event OnUpgradeLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnConfirmUpgradeLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnStartLearn(address user, uint256 tokenId, uint256 level, uint256 startBlockLearn, uint256 pendingBlockLearn);
    event OnStopLearn(address user, uint256 tokenId, uint256 level, uint256 totalBlockLearnEachTime, uint256 stopBlockLearn);
    event OnBonusReward(address user, uint256 AmountTokenReward);

    struct LearnData
    {
        bool Learning; //a boolean that indicates whether the user is currently in a learning session             
        uint256 StartBlockLearn; //the block at which the user started the current learning session
        uint256 StopBlockLearn; //the block at which the user stopped the current learning session
        uint256 PendingBlockLearn; //the number of blocks remaining until the current learning session is complete
    }

    struct RobotData
    {
        uint256 BlockJoin; // the block at which the NFT robot was added to the game
        uint256 TokenId; // the ID of the NFT robot
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
    function PauseSystem() public onlyOwner 
    {
        _pause();
    }

    function UnpauseSystem() public onlyOwner
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

    //user action
    
    /**
    allows the user to join the game by transferring their robot NFT to the game contract, 
    and records the robot's data including the block number at which it joined 
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
    allows a user to remove their robot NFT from the game. 
    If the user's robot is currently in the process of learning, 
    the function stops the learning process. 
    The function returns an error if the robot could not be removed from the game.
    */
    function LetRobotNFTOutOfTheGame() public 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        require(robotData.TokenId != 0, "Error OutGame: Haven't joined the game");

        LearnData memory data = DataUserLearn[user]; 
        if (data.Learning == true) 
        {
            ForRobotNFTStopLearn();
        }
        require(removeRobot(msg.sender) == true, "Error OutGame: removeRobot");
    }

    /**
    allows users to upgrade the level of their robot NFT if they have enough balance. 
    It checks if the robot NFT is valid and the user has enough balance to pay the price of upgrading the level.
     */
    function UpgradeLevelRobot() public whenNotPaused
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error UpgradeLevelRobot: Invalid tokenId");

        uint256 level = Robot.Level(tokenId);
        require(level < MaxLevelOfRobotNFTInGame, "Error UpgradeLevelRobot: Invalid level");
        require(TokenReward.balanceOf(user) >= PriceUpgradeLevelRobotNFT[level.add(1)], "Error UpgradeLevelRobot: Invalid balance");
        
        TokenReward.transferFrom(user, address(this), PriceUpgradeLevelRobotNFT[level.add(1)]);

        PendingBlockUpgradeLevelRobotNFT[tokenId] = block.number.add(BlockUpgradeLevelRobotNFT[level.add(1)]);

        emit OnUpgradeLevelRobot(user, tokenId, level);
    }

    /**
    confirms that the user's robot is ready to upgrade to the next level, 
    updates the 'PendingBlockUpgradeLevelRobotNFT' to 0,
    and upgrades the level of the robot.
    */
    function ConfirmUpgradeLevelRobot() public whenNotPaused
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(PendingBlockUpgradeLevelRobotNFT[tokenId] > 0, "Error ConfirmUpgradeLevelRobot: Validate");
        require(block.number >= PendingBlockUpgradeLevelRobotNFT[tokenId], "Error ConfirmUpgradeLevelRobot: Time out");
        PendingBlockUpgradeLevelRobotNFT[tokenId] = 0;
        Robot.UpgradeLevel(tokenId);

        emit OnConfirmUpgradeLevelRobot(user, tokenId, Robot.Level(tokenId));
    }

    /**
    allows the user who called the function to start their robot's learning process 
    */
    function ForRobotNFTToLearn() public whenNotPaused 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error StartLearning: Invalid tokenId");

        LearnData storage data = DataUserLearn[user]; 
        require(data.StartBlockLearn < block.number, "Error StartLearning: Time out");
        require(data.Learning == false, "Error StartLearning: Learning");

        if(data.PendingBlockLearn == 0)
        {
            data.PendingBlockLearn = TotalBlockLearnEachTime;
        }

        data.StartBlockLearn = block.number;
        data.Learning = true;

        emit OnStartLearn(user, tokenId, Robot.Level(tokenId), data.StartBlockLearn, data.PendingBlockLearn);
    }

    /*
    allows the user who called the function to stop their robot's learning process and
    receive bonus tokens based on the number of blocks learned
     */
    function ForRobotNFTStopLearn() public whenNotPaused
    {
        address user = msg.sender;

        LearnData storage data = DataUserLearn[user]; 
        require(data.Learning == true, "Error StopLearning: Not learning");

        uint256 totalBlockLearnedOfUser = block.number.sub(data.StartBlockLearn);
        if(totalBlockLearnedOfUser >= data.PendingBlockLearn)
        {
            totalBlockLearnedOfUser = data.PendingBlockLearn;

            data.StartBlockLearn = block.number.add(DelayBlockLearnNextTime);
            data.PendingBlockLearn = 0;
        }
        else
        {
            data.PendingBlockLearn = data.PendingBlockLearn.sub(totalBlockLearnedOfUser);
        }
        data.Learning = false;
        data.StopBlockLearn = block.number;

        DoBonusToken(user, totalBlockLearnedOfUser);
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
            uint256 totalBlockLearned = TotalBlockLearnEachTime.sub(pendingBlockLearn);
            uint256 totalBlockLearnEachTimeing = blockNumber.sub(startBlockLearn);

            rewardPerDay = (startBlockLearn < stopBlockLearn) ?
                totalBlockLearned.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) :
                    ((totalBlockLearned.add(totalBlockLearnEachTimeing))
                        .mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser]) <
                        TotalBlockLearnEachTime.mul(RewardPerBlockOfLevel[levelRobotJoinGameOfUser])) ? 
                            (totalBlockLearned.add(totalBlockLearnEachTimeing))
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
    rewards a specified 'user' with bonus tokens based on the level of their robot and
    a specified 'totalBlockLearned' value. 
     */
    function DoBonusToken(address user, uint256 totalBlockLearned) private 
    {
        RobotData memory robotData = RobotJoinGameOfUser[user];
        uint256 tokenId = robotData.TokenId;
        uint256 level = Robot.Level(tokenId);
        uint256 rewardPerBlock = RewardPerBlockOfLevel[level];
        if(TokenReward.balanceOf(address(this)) >= totalBlockLearned.mul(rewardPerBlock))
        {
            TokenReward.transfer(user, totalBlockLearned.mul(rewardPerBlock));

            emit OnBonusReward(user, totalBlockLearned.mul(rewardPerBlock));
        }
        else
        {
            TokenReward.transfer(user, TokenReward.balanceOf(address(this)));

            emit OnBonusReward(user, TokenReward.balanceOf(address(this)));
        }
    }  

    /** 
   removes the NFT robot of a specified 'user' from the game contract 
   if the robot has been in the game for a specified amount of time.
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