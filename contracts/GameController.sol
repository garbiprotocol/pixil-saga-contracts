// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IHero.sol";
import "./interfaces/IRobot.sol";
import "./interfaces/ILearning.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract GameController is Ownable, IERC721Receiver, Pausable
{
    IHero public  HeroNFT;      // 
    IRobot public RobotNFT;
    ILearning public LearningContract;

    using SafeMath for uint256;

    mapping(address => uint256) public HeroNFTJoinGameOfUser;
    mapping(address => RobotData) public RobotNFTJoinGameOfUser;

    mapping(address => bool) public UserClaimedRobotNFT;

    uint256 public DelayBlockRobotNFTOutGame;

    IERC20 public ERC20CreditToken;         // GRB
    uint256 public PriceCreditMint = 1e18;  // 1GRB

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
    }

    struct RobotData
    {
        uint256 BlockJoin; // the block at which the NFT robot was added to the game
        uint256 RobotId; // the ID of the NFT robot
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

    function SetHeroNFT(IHero heroNFT) public onlyOwner 
    {
        HeroNFT = heroNFT;
    }

    function SetRobotNFT(IRobot robotNFT) public onlyOwner 
    {
        RobotNFT = robotNFT;
    }

    function SetLearningContract(ILearning learningContract) public onlyOwner 
    {
        LearningContract = learningContract;
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

    function MintHeroNFT(uint256 teamId) public whenNotPaused
    {
        address user = _msgSender();
        require(ERC20CreditToken.balanceOf(user) >= PriceCreditMint, "Error Mint: Invalid balance");
        ERC20CreditToken.transferFrom(user, address(this), PriceCreditMint);

        if(HeroNFTJoinGameOfUser[user] == 0)
        {
            uint256 heroId = HeroNFT.Mint(address(this), teamId);
            HeroNFTJoinGameOfUser[user] = heroId;
        }
        else
        {
            HeroNFT.Mint(user, teamId);
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

    /*
    allows the user to join the game by transferring their Hero NFT to the game contract.
    */
    function LetHeroNFTJoinToGame(uint256 heroId) public whenNotPaused
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

        require(HeroNFTJoinGameOfUser[user] > 0, "Error removeHeroNFTOfGame: Invalid HeroId");
        require(removeHeroNFT(user) == true, "LetHeroNFTOutOfGame: RemoveHeroNFT");   
    }

    /**
    allows the user to join the game by transferring their robot NFT to the game contract, 
    and records the robot's data including the block number at which it joined 
     */
    function LetRobotNFTJoinToGame(uint256 robotId) public whenNotPaused
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