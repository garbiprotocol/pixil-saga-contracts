// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IHero.sol";
import "./interfaces/IRobot.sol";
import "./interfaces/ILearning.sol";
import "./interfaces/IWhiteList.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract GameController is Ownable, IERC721Receiver, Pausable
{
    IWhiteList public WhiteList;
    IHero public  HeroNFT;       
    IRobot public RobotNFT;
    ILearning public LearningContract;

    using SafeMath for uint256;

    mapping(address => uint256) public HeroNFTJoinGameOfUser;
    mapping(address => RobotData) public RobotNFTJoinGameOfUser;

    mapping(address => bool) public UserClaimedRobotNFT;
    
    mapping(address => bool) public ListAddressMintFree;

    uint256 public DelayBlockRobotNFTOutGame;

    IERC20 public ERC20CreditToken;         // GRB
    uint256 public PriceCreditMint = 9e18;  // 9GRB

    event OnMint(address indexed user, uint256 heroId, uint256 teamId, uint256 indexed amount);
    event OnHeroNFTJoinedGame(address indexed user, uint256 indexed heroId);
    event OnHeroNFTOutOfGame(address indexed user, uint256 indexed heroId);
    event OnRobotNFTJoinedGame(address indexed user, uint256 indexed robotId);
    event OnRobotNFTOutOfGame(address indexed user, uint256 indexed robotId);

    constructor(IHero heroNFT, IRobot robotNFT, ILearning learningContract, IERC20 erc20CreditToken)
    {
        HeroNFT = heroNFT;
        RobotNFT = robotNFT;
        LearningContract = learningContract;
        ERC20CreditToken = erc20CreditToken;

        DelayBlockRobotNFTOutGame = 7000;   // 1 day
    }

    struct RobotData
    {
        uint256 BlockJoin; // the block at which the NFT robot was added to the game
        uint256 RobotId; // the ID of the NFT robot
    }

    modifier onlyWhiteList()
    {
        if(msg.sender != tx.origin)
        {
            require(WhiteList.whitelisted(msg.sender) == true, "invalid whitelist");
        }
        _;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    function PauseSystem() public onlyOwner 
    {
        _pause();
    }

    function UnpauseSystem() public onlyOwner
    {
        _unpause();
    }

    function SetWhiteListcontract(IWhiteList addressWhiteList) public onlyOwner 
    {
        WhiteList = addressWhiteList;
    }

    function SetListAddressMintFree(address[] memory listAddress) public onlyOwner 
    {
        for(uint256 index = 0; index < listAddress.length; index ++)
        {
            ListAddressMintFree[listAddress[index]] = true;
        }
    }

    function RemoveListAddressMintFree(address[] memory listAddress) public onlyOwner 
    {
        for(uint256 index = 0; index < listAddress.length; index ++)
        {
            ListAddressMintFree[listAddress[index]] = false;
        }
    }

    function SetHeroNFTContract(IHero addressHeroNFT) public onlyOwner 
    {
        HeroNFT = addressHeroNFT;
    }

    function SetRobotNFTContract(IRobot addressRobotNFT) public onlyOwner 
    {
        RobotNFT = addressRobotNFT;
    }

    function SetLearningContract(ILearning addressLearningContract) public onlyOwner 
    {
        LearningContract = addressLearningContract;
    }

    function SetDelayBlockRobotNFTOutGame(uint256 value) public onlyOwner
    {
        DelayBlockRobotNFTOutGame = value;
    }

    function SetERC20CreditToken(IERC20 erc20CreditToken) public onlyOwner 
    {
        ERC20CreditToken = erc20CreditToken;
    }

    function SetPriceCreditMint(uint256 value) public onlyOwner
    {
        PriceCreditMint = value;
    }

    function MintHeroNFT(uint256 teamId) public whenNotPaused onlyWhiteList
    {
        address user = _msgSender();
        require(ERC20CreditToken.balanceOf(user) >= PriceCreditMint, "Error Mint: Invalid balance");

        uint256 amountTokenInput = ListAddressMintFree[user] == true ? 0 : PriceCreditMint;

        if(amountTokenInput == 0)
        {
            ListAddressMintFree[user] = false;
        }

        ERC20CreditToken.transferFrom(user, address(this), amountTokenInput);

        if(HeroNFTJoinGameOfUser[user] == 0)
        {
            uint256 heroId = HeroNFT.Mint(address(this), teamId);
            HeroNFTJoinGameOfUser[user] = heroId;
            emit OnMint(user, heroId, teamId, amountTokenInput);
        }
        else
        {
            uint256 heroId = HeroNFT.Mint(user, teamId);
            emit OnMint(user, heroId, teamId, amountTokenInput);
        }

        if(UserClaimedRobotNFT[user] == false)
        {
            ClaimRobotNFT(user);
        }
    }

    function ClaimRobotNFT(address user) private whenNotPaused 
    {
        uint256 robotId = RobotNFT.Mint(address(this));

        UserClaimedRobotNFT[user] = true;

        RobotData storage robotDataOfUser = RobotNFTJoinGameOfUser[user];
        robotDataOfUser.BlockJoin = block.number;
        robotDataOfUser.RobotId = robotId;
    }

    function MigrateData(address user, uint256 teamId, uint256 levelRobot) public onlyOwner
    {
        uint256 heroId = HeroNFT.Mint(address(this), teamId);
        HeroNFTJoinGameOfUser[user] = heroId;

        uint256 robotId = RobotNFT.Mint(address(this));
        UserClaimedRobotNFT[user] = true;

        RobotData storage robotDataOfUser = RobotNFTJoinGameOfUser[user];
        robotDataOfUser.BlockJoin = block.number;
        robotDataOfUser.RobotId = robotId;

        for(uint256 index = 0; index < levelRobot; index++)
        {
            RobotNFT.UpgradeLevel(robotId);
        }
    }

    /*
    allows the user to join the game by transferring their Hero NFT to the game contract.
    */
    function LetHeroNFTJoinToGame(uint256 heroId) public whenNotPaused onlyWhiteList
    {
        address user = _msgSender();
        require(HeroNFT.ownerOf(heroId) == user, "Error JoinHeroNFTToGame: Invalid HeroId");
        require(removeHeroNFT(user) == true, "Error JoinHeroNFTToGame: Remove HeroNFT");

        HeroNFT.safeTransferFrom(user, address(this), heroId);

        HeroNFTJoinGameOfUser[user] = heroId;

        emit OnHeroNFTJoinedGame(user, heroId);
    }

    /*
    allows a user to remove their Hero NFT from the game.
    */
    function LetHeroNFTOutOfGame() public 
    {
        address user = _msgSender();

        require(removeHeroNFT(user) == true, "LetHeroNFTOutOfGame: RemoveHeroNFT");   
    }

    /**
    allows the user to join the game by transferring their robot NFT to the game contract, 
    and records the robot's data including the block number at which it joined 
     */
    function LetRobotNFTJoinToGame(uint256 robotId) public whenNotPaused onlyWhiteList
    {
        address user = _msgSender();
        require(RobotNFT.ownerOf(robotId) == user, "Error JoinGame: Invalid token");
        require(removeRobotNFT(user) == true, "Error JoinGame: remove");

        RobotNFT.safeTransferFrom(user, address(this), robotId);

        RobotData storage robotDataOfUser = RobotNFTJoinGameOfUser[user];
        robotDataOfUser.BlockJoin = block.number;
        robotDataOfUser.RobotId = robotId;

        emit OnRobotNFTJoinedGame(user, robotId);
    }

    /**
    allows a user to remove their robot NFT from the game. 
    If the user's robot is currently in the process of learning, 
    the function stops the learning process. 
    The function returns an error if the robot could not be removed from the game.
    */
    function LetRobotNFTOutOfGame() public 
    {
        address user = _msgSender();
        RobotData memory robotDataOfUser = RobotNFTJoinGameOfUser[user];
        require(robotDataOfUser.RobotId != 0, "Error Robot NFT OutGame: Haven't joined the game");

        (bool learning,,,) = LearningContract.DataUserLearn(user);
        require(learning == false, "Error Robot NFT OutGame: Learning");
        require(removeRobotNFT(user) == true, "Error Robot NFT OutGame: removeRobotNFT");
    }

    /** 
    removes the NFT robot of a specified 'user' from the game contract 
    if the robot has been in the game for a specified amount of time.
    */
    function removeHeroNFT(address user) private returns(bool)
    {
        uint256 heroId = HeroNFTJoinGameOfUser[user];

        if(heroId == 0) return true;
        
        HeroNFT.safeTransferFrom(address(this), user, heroId);

        HeroNFTJoinGameOfUser[user] = 0;

        emit OnHeroNFTOutOfGame(user, heroId);
        
        return true;
    }

    /** 
    removes the NFT robot of a specified 'user' from the game contract 
    if the robot has been in the game for a specified amount of time.
    */
    function removeRobotNFT(address user) private returns(bool)
    {
        RobotData storage robotData = RobotNFTJoinGameOfUser[user];
        uint256 robotId = robotData.RobotId;

        if(robotId == 0) return true;
        
        require(robotData.BlockJoin.add(DelayBlockRobotNFTOutGame) <= block.number, "Error removeRobotNFT: Time out");
        RobotNFT.safeTransferFrom(address(this), user, robotId);

        robotData.RobotId = 0;

        emit OnRobotNFTOutOfGame(user, robotId);

        return true;
    }

    function GetDataUser(address user) public view returns (
        uint256 avatarId,
        uint256 teamId,
        uint256 robotId,
        uint256 blockRobotJoin,
        uint256 delayBlockRobotNFTOutGame,
        uint256 blockNumber
        )
    {

        avatarId = HeroNFTJoinGameOfUser[user];
        teamId = HeroNFT.TeamId(avatarId);
        robotId = RobotNFTJoinGameOfUser[user].RobotId;
        blockRobotJoin = RobotNFTJoinGameOfUser[user].BlockJoin;
        delayBlockRobotNFTOutGame = DelayBlockRobotNFTOutGame;
        blockNumber = block.number;
    }

    function WithdrawCredit() public onlyOwner 
    {
        address to = owner();
        ERC20CreditToken.transfer(to, ERC20CreditToken.balanceOf(address(this)));
    }
}