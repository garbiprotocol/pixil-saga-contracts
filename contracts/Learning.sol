// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IRobot.sol";

contract Learning is Ownable, IERC721Receiver
{
    using SafeMath for uint256;

    IRobot public Robot;          // NFT learn
    IERC20 public TokenReward;     // Reward

    mapping(address => Learn) public DataUserLearn;
    mapping(address => RobotData) public RobotJoin;
    mapping(uint256 => uint256) public PendingBlockUpgrate;
    // config
    bool public EnableSystem;
    uint256 public DelayBlockOutGame;

    mapping(uint256 => uint256) public PriceUpgrate; 
    mapping(uint256 => uint256) public BlockUpgrate; 
    uint256 public MaxLevel;
    uint256 public DelayBlockLearn;
    uint256 public TotalBlockLearn;

    mapping(uint256 => uint256) public RewardPerBlockOfLevel;

    event OnJoinGame(address user, uint256 tokenId);
    event OnOutGame(address user, uint256 tokenId);
    event OnUpgrateLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnConfirmUpgrateLevelRobot(address user, uint256 tokenId, uint256 level);
    event OnStartLearn(address user, uint256 tokenId, uint256 level, uint256 startBlockLearn, uint256 pendingBlockLearn);
    event OnStopLearn(address user, uint256 tokenId, uint256 level, uint256 totalBlockLearn, uint256 stopBlockLearn);
    event OnBonusReward(address user, uint256 AmountTokenReward);

    modifier IsEnableSystem()
    {
        require(EnableSystem == true, "System paused");
        _;
    }
    
    struct Learn
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

        EnableSystem = true;
        
        // Test
        DelayBlockOutGame = 50;
        TotalBlockLearn = 30;       
        DelayBlockLearn = 10;

        PriceUpgrate[0] = 0;
        PriceUpgrate[1] = 100e18;
        PriceUpgrate[2] = 200e18;
        PriceUpgrate[3] = 300e18;

        BlockUpgrate[0] = 0;
        BlockUpgrate[1] = 100;
        BlockUpgrate[2] = 200;
        BlockUpgrate[3] = 300;

        RewardPerBlockOfLevel[0] = 5e17;
        RewardPerBlockOfLevel[1] = 1e18;
        RewardPerBlockOfLevel[2] = 2e18;
        RewardPerBlockOfLevel[3] = 3e18;

        MaxLevel = 3;
    }


    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    // owner acction
    function SetPauseSystem() public onlyOwner 
    {
        EnableSystem = false;
    }

    function SetEnableSystem() public onlyOwner
    {
        EnableSystem = true;
    }

    function SetDelayBlockOutGame(uint256 value) public onlyOwner 
    {
        DelayBlockOutGame = value;
    }

    function SetMaxLevel(uint256 maxLevel) public onlyOwner 
    {
        MaxLevel = maxLevel;
    }

    function SetTotalBlockLearn(uint256 totalBlockLearn) public onlyOwner
    {
        TotalBlockLearn = totalBlockLearn;
    }

    function SetRewardPerBlockOfLevel(uint256 level, uint256 value) public onlyOwner 
    {
        require(level <= MaxLevel, "Invalid max level");
        RewardPerBlockOfLevel[level] = value;
    }

    function SetPriceUpgrate(uint256 level, uint256 price) public onlyOwner
    {
        require(level <= MaxLevel,  "Error SetPriceUpgrate: Invalid level");
        PriceUpgrate[level] = price;
    }

    function SetBlockUpgrate(uint256 level, uint256 quantityBlock) public onlyOwner
    {
        require(level <= MaxLevel,  "Error SetBlockUpgrate: Invalid level");
        BlockUpgrate[level] = quantityBlock;
    }

    function JoinGame(uint256 tokenId) public IsEnableSystem
    {
        address user = msg.sender;
        require(Robot.ownerOf(tokenId) == user, "Error JoinGame: Invalid token");
        require(removeRobot(user) == true, "Error JoinGame: remove");

        Robot.safeTransferFrom(user, address(this), tokenId);

        RobotData storage robotData = RobotJoin[user];
        robotData.BlockJoin = block.number;
        robotData.TokenId = tokenId;

        emit OnJoinGame(msg.sender, tokenId);
    }

    function OutGame() public 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoin[user];
        require(robotData.TokenId != 0, "Error OutGame: Haven't joined the game");

        Learn memory data = DataUserLearn[user]; 
        if (data.StartBlockLearn > data.StopBlockLearn) 
        {
            StopLearn();
        }
        require(removeRobot(msg.sender) == true, "Error OutGame: removeRobot");
    }

    function UpgrateLevelRobot() public IsEnableSystem
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoin[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error UpgrateLevelRobot: Invalid tokenId");

        uint256 level = Robot.Level(tokenId);
        require(level < MaxLevel, "Error UpgrateLevelRobot: Invalid level");
        require(TokenReward.balanceOf(user) >= PriceUpgrate[level.add(1)], "Error UpgrateLevelRobot: Invalid balance");
        
        TokenReward.transferFrom(user, address(this), PriceUpgrate[level.add(1)]);

        PendingBlockUpgrate[tokenId] = block.number.add(BlockUpgrate[level.add(1)]);

        emit OnUpgrateLevelRobot(user, tokenId, level);
    }

    function ConfirmUpgrateLevelRobot() public IsEnableSystem
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoin[user];
        uint256 tokenId = robotData.TokenId;
        require(PendingBlockUpgrate[tokenId] > 0, "Error ConfirmUpgrateLevelRobot: Validate");
        require(block.number >= PendingBlockUpgrate[tokenId], "Error ConfirmUpgrateLevelRobot: Time out");
        PendingBlockUpgrate[tokenId] = 0;
        Robot.UpgrateLevel(tokenId);

        emit OnConfirmUpgrateLevelRobot(user, tokenId, Robot.Level(tokenId));
    }

    function StartLearn() public IsEnableSystem 
    {
        address user = msg.sender;
        RobotData memory robotData = RobotJoin[user];
        uint256 tokenId = robotData.TokenId;
        require(tokenId != 0, "Error StartLearn: Invalid tokenId");

        Learn storage data = DataUserLearn[user]; 
        require(data.StartBlockLearn < block.number, "Error StartLearn: Time out");
        require(data.Learning == false, "Error StartLearn: Learning");

        if(data.PendingBlockLearn == 0)
        {
            data.PendingBlockLearn = TotalBlockLearn;
        }

        data.StartBlockLearn = block.number;
        data.Learning = true;

        emit OnStartLearn(user, tokenId, Robot.Level(tokenId), data.StartBlockLearn, data.PendingBlockLearn);
    }

    function StopLearn() public IsEnableSystem
    {
        address user = msg.sender;

        Learn storage data = DataUserLearn[user]; 
        require(data.Learning == true, "Error StopLearn: Not learning");

        uint256 totalBlockLearnedOfUser = block.number.sub(data.StartBlockLearn);
        if(totalBlockLearnedOfUser >= data.PendingBlockLearn)
        {
            totalBlockLearnedOfUser = data.PendingBlockLearn;

            data.StartBlockLearn = block.number.add(DelayBlockLearn);
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
        uint256 levelRobotJoin,
        uint256 blockNumber,
        bool learning,
        uint256 startBlockLearn,
        uint256 stopBlockLearn,
        uint256 pendingBlockLearn,
        uint256 rewardPerDay,
        uint256 pendingBlockUpgrate
    )
    {
        cyberCreditBalance = TokenReward.balanceOf(user);
        RobotData memory robotData = RobotJoin[user];
        tokenId = robotData.TokenId;
        levelRobotJoin = Robot.Level(tokenId);
        blockNumber = block.number;

        Learn memory data = DataUserLearn[user];
        learning = data.Learning;
        startBlockLearn = data.StartBlockLearn;
        pendingBlockLearn = data.PendingBlockLearn;
        stopBlockLearn = data.StopBlockLearn;

        if(pendingBlockLearn != 0) 
        {
            uint256 totalBlockLearned = TotalBlockLearn.sub(pendingBlockLearn);
            uint256 totalBlockLearning = blockNumber.sub(startBlockLearn);

            rewardPerDay = (startBlockLearn < stopBlockLearn) ?
                totalBlockLearned.mul(RewardPerBlockOfLevel[levelRobotJoin]) :
                    ((totalBlockLearned.add(totalBlockLearning))
                        .mul(RewardPerBlockOfLevel[levelRobotJoin]) <
                        TotalBlockLearn.mul(RewardPerBlockOfLevel[levelRobotJoin])) ? 
                            (totalBlockLearned.add(totalBlockLearning))
                            .mul(RewardPerBlockOfLevel[levelRobotJoin]) :
                                TotalBlockLearn.mul(RewardPerBlockOfLevel[levelRobotJoin]);
        }

        pendingBlockUpgrate  = PendingBlockUpgrate[tokenId];
        
    }

    function GetConfigSystem() public view returns(
        uint256 maxLevel,
        uint256[] memory priceUpgrateLevel,
        uint256 totalBlockLearn,
        uint256[] memory rewardPerBlockOfLevel,
        uint256[] memory blockUpgrate
    )
    {
        maxLevel = MaxLevel;

        priceUpgrateLevel = new uint256[](maxLevel.add(1));
        for(uint level = 1; level <= maxLevel; level++)
        {
            priceUpgrateLevel[level] = PriceUpgrate[level]; 
        }

        totalBlockLearn = TotalBlockLearn;

        rewardPerBlockOfLevel = new uint256[](maxLevel.add(1));
        for(uint level = 0; level <= maxLevel; level++)
        {
            rewardPerBlockOfLevel[level] = RewardPerBlockOfLevel[level];
        }

        blockUpgrate = new uint256[](maxLevel.add(1));
        for(uint level = 0; level <= maxLevel; level++)
        {
            blockUpgrate[level] = BlockUpgrate[level];
        }
    }

    function DoBonusToken(address user, uint256 totalBlockLearned) private 
    {
        RobotData memory robotData = RobotJoin[user];
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

    function removeRobot(address user) private returns(bool)
    {
        RobotData storage robotData = RobotJoin[user];
        uint256 tokenId = robotData.TokenId;

        if(tokenId == 0) return true;
        
        require(robotData.BlockJoin.add(DelayBlockOutGame) <= block.number, "Error removeRobot: Time out");
        Robot.safeTransferFrom(address(this), user, tokenId);

        robotData.TokenId = 0;

        emit OnOutGame(msg.sender, tokenId);
        return true;
    }
}