// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// NFT
contract HeroNFT is ERC721Enumerable, Ownable, Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter private HeroId;

    address public Miner;   // GameController

    string public BaseURI;

    uint256 public MaxTeamId;

    mapping(uint256 => uint256) public TeamId;

    event OnMintNFT(address from, address to, uint256 HeroId);

    constructor(
        string memory tokenName, string memory tokenSymbol
        ) ERC721 (tokenName, tokenSymbol) 
    {
        MaxTeamId = 4;
    }

    function SetPauseSystem() public onlyOwner 
    {
        _pause();
    }

    function SetEnableSystem() public onlyOwner
    {
        _unpause();
    }

    function SetMiner(address miner) public onlyOwner 
    {
        Miner = miner;
    }

    function SetMaxTeamId(uint256 value) public onlyOwner 
    {
        require(value >= 1, "Error SetMaxTeamId: invalid value");
        MaxTeamId = value;
    }

    function SetBaseURI(string memory baseURI) public onlyOwner 
    {
        require(bytes(baseURI).length > 0, "Error SetBaseURI: Invalid baseURI");
        BaseURI = baseURI;
    }

    function Mint(address to, uint256 teamId) public whenNotPaused returns(uint256)
    {
        require(msg.sender == Miner, "Error Mint: Invalid Miner");
        require(teamId >= 1 && teamId <= MaxTeamId, "Error Mint: Invalid teamId");
        HeroId.increment();
        uint256 newHeroId = HeroId.current();
        _safeMint(to, newHeroId);
        TeamId[newHeroId] = teamId;

        emit OnMintNFT(msg.sender, to, newHeroId);

        return newHeroId;
    }

    function Burn(uint256 heroId) public whenNotPaused virtual
    {
        require(_isApprovedOrOwner(msg.sender, heroId), "Burn caller is not owner nor approved");
        _burn(heroId);
    }

    function _baseURI() internal view override returns(string memory)
    {
        return BaseURI;
    }
}