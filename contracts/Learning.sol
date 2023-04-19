// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGameController.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IRobot.sol";

contract Learning is Ownable, IERC721Receiver, Pausable
{
    using SafeMath for uint256;
    IGameController public GameCotrollerContract;
    IRobot public Robot;          // NFT learn
    IERC20 public TokenReward;     // CyberCredit

    // stores the LearnData of each user.
    mapping(address => LearnData) public DataUserLearn;

    //stores the block number of the pending level upgrade for each robot NFT.
    mapping(uint256 => uint256) public PendingBlockUpgradeLevelRobotNFT;

    // config

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
    event OnUpgradeLevelRobot(address user, uint256 tokenId, uint256 level);
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

    constructor(
        IRobot robot,
        IERC20 tokenReward)
    {
        Robot = robot;
        TokenReward = tokenReward;
        
        // Test
        TotalBlockLearnEachTime = 1024;       
        DelayBlockLearnNextTime = 4096;

        PriceUpgradeLevelRobotNFT[0] = 0;
        PriceUpgradeLevelRobotNFT[1] = 5461e18;
        PriceUpgradeLevelRobotNFT[2] = 65536e18;
        PriceUpgradeLevelRobotNFT[3] = 131072e18;

        BlockUpgradeLevelRobotNFT[0] = 0;
        BlockUpgradeLevelRobotNFT[1] = 300;
        BlockUpgradeLevelRobotNFT[2] = 7000;
        BlockUpgradeLevelRobotNFT[3] = 28000;

        RewardPerBlockOfLevel[0] = 0;
        RewardPerBlockOfLevel[1] = 1e18;
        RewardPerBlockOfLevel[2] = 4e18;
        RewardPerBlockOfLevel[3] = 16e18;

        MaxLevelOfRobotNFTInGame = 3;
    }

    modifier isHeroNFTJoinGame()
    {
        address user = _msgSender();
        require(GameCotrollerContract.HeroNFTJoinGameOfUser(user) != 0, "Error: Invaid HeroNFT join game.");
        _;
    }

    modifier isNotUpgradeRobot()
    {
        address user = _msgSender();
        (,uint256 robotId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(block.number > PendingBlockUpgradeLevelRobotNFT[robotId], "Error: Robot upgraded.");
        _;
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

    function SetGameCotrollerContract(IGameController gameCotrollerContract) public onlyOwner 
    {
        GameCotrollerContract = gameCotrollerContract;
    }

    function SetRobotNFTContract(IRobot addressRobotNFT)public onlyOwner 
    {
        Robot = addressRobotNFT;
    }

    function SetTokenRewardContract(IERC20 addressTokenReward) public onlyOwner
    {
        TokenReward = addressTokenReward;
    }

    function SetMaxLevelOfRobotNFTinGame(uint256 newMaxLevelOfRobotNFTinGame) public onlyOwner 
    {
        MaxLevelOfRobotNFTInGame = newMaxLevelOfRobotNFTinGame;
    }

    function SetTotalBlockLearnEachTime(uint256 newTotalBlockLearnEachTime) public onlyOwner
    {
        TotalBlockLearnEachTime = newTotalBlockLearnEachTime;
    }

    function SetRewardPerBlockOfLevel(uint256 level, uint256 rewardPerBlock) public onlyOwner 
    {
        require(level <= MaxLevelOfRobotNFTInGame, "Invalid max level");
        RewardPerBlockOfLevel[level] = rewardPerBlock;
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

    function SetDelayBlockLearnNextTime(uint256 newDelayBlockLearnNextTime) public onlyOwner 
    {
        DelayBlockLearnNextTime = newDelayBlockLearnNextTime;
    }

    //user action
    function UpgradeLevelRobot() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
    {
        address user = msg.sender;
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(tokenId != 0, "Error UpgradeLevelRobot: Invalid tokenId");

        uint256 level = Robot.Level(tokenId);
        require(level < MaxLevelOfRobotNFTInGame, "Error UpgradeLevelRobot: Invalid level");
        require(TokenReward.balanceOf(user) >= PriceUpgradeLevelRobotNFT[level.add(1)], "Error UpgradeLevelRobot: Invalid balance");
        LearnData memory data = DataUserLearn[user];
        require(data.Learning == false, "Error UpgradeLevelRobot: Learning");
        TokenReward.transferFrom(user, address(this), PriceUpgradeLevelRobotNFT[level.add(1)]);

        PendingBlockUpgradeLevelRobotNFT[tokenId] = block.number.add(BlockUpgradeLevelRobotNFT[level.add(1)]);
        Robot.UpgradeLevel(tokenId);
        emit OnUpgradeLevelRobot(user, tokenId, level);
    }

    function ForRobotNFTToLearn() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
    {
        address user = msg.sender;
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        require(tokenId != 0, "Error StartLearning: Invalid tokenId");
        require(Robot.Level(tokenId) > 0, "Error: Robot Level is 0");

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

    function ForRobotNFTStopLearn() public whenNotPaused isHeroNFTJoinGame isNotUpgradeRobot
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
        (,tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
        
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

    function DoBonusToken(address user, uint256 totalBlockLearned) private
    {
        (,uint256 tokenId) = GameCotrollerContract.RobotNFTJoinGameOfUser(user);
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
}