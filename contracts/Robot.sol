// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// NFT
contract Robot is ERC721Enumerable, Ownable, Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter private TokenId;

    mapping(address => bool) public Operator;

    string public BaseURI;

    event OnMintNFT(address from, address to, uint256 tokenId);
    event OnUpgradeLevelRobot(uint256 tokenId, uint256 newLevel);

    mapping(uint256 => uint256) public Level;

    constructor(
        string memory tokenName, string memory tokenSymbol
        ) ERC721 (tokenName, tokenSymbol) {}

    function SetPauseSystem() public onlyOwner 
    {
        _pause();
    }

    function SetEnableSystem() public onlyOwner
    {
        _unpause();
    }

    function SetEnableOperator(address addressOperator) public onlyOwner 
    {
        require(Operator[addressOperator] == false, "Error SetEnableOperator: Invalid Operator");
        Operator[addressOperator] = true;
    }

    function SetDisableOperator(address addressOperator) public onlyOwner
    {
        require(Operator[addressOperator] == true, "Error SetEnableOperator: Invalid Operator");
        Operator[addressOperator] = false;
    }

    function SetBaseURI(string memory baseURI) public onlyOwner 
    {
        require(bytes(baseURI).length > 0, "Error SetBaseURI: Invalid baseURI");
        BaseURI = baseURI;
    }

    function Mint(address to) public whenNotPaused returns(uint256)
    {
        require(Operator[msg.sender] == true, "Error Mint: Invalid miner");
        TokenId.increment();
        uint256 newTokenId = TokenId.current();
        _safeMint(to, newTokenId);
        Level[newTokenId] = 0;

        emit OnMintNFT(msg.sender, to, newTokenId);

        return newTokenId;
    }

    function Burn(uint256 tokenId) public whenNotPaused virtual
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Burn caller is not owner not approved");
        _burn(tokenId);
    }

    function UpgradeLevel(uint256 tokenId) public whenNotPaused
    {
        require(Operator[msg.sender] == true, "Error UpgradeLevel");
        require(_exists(tokenId), "Error UpgradeLevel: Token does not exist");
        Level[tokenId] += 1;

        emit OnUpgradeLevelRobot(tokenId, Level[tokenId]);
    }

    function SetLevelRobot(uint256 tokenId, uint256 level) public whenNotPaused 
    {
        require(Operator[msg.sender] == true, "Error SetLevelRobot");
        require(_exists(tokenId), "Error UpgradeLevel: Token does not exist");
        Level[tokenId] = level;
    }

    function _baseURI() internal view override returns(string memory)
    {
        return BaseURI;
    }

}