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

    mapping(address => bool) public Miner;

    string public BaseURI;

    event OnMintNFT(address from, address to, uint256 tokenId);

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

    function SetEnableMiner(address miner) public onlyOwner 
    {
        require(Miner[miner] == false, "Error SetEnableMiner: Invalid miner");
        Miner[miner] = true;
    }

    function SetDisableMiner(address miner) public onlyOwner
    {
        require(Miner[miner] == true, "Error SetDisableMiner: Invalid miner");
        Miner[miner] = false;
    }

    function SetBaseURI(string memory baseURI) public onlyOwner 
    {
        require(bytes(baseURI).length > 0, "Error SetBaseURI: Invalid baseURI");
        BaseURI = baseURI;
    }

    function Mint(address to) public whenNotPaused returns(uint256)
    {
        require(Miner[msg.sender] == true, "Error Mint: Invalid miner");
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
        require(Miner[msg.sender] == true, "Error UpgradeLevel");
        require(_exists(tokenId), "Error UpgradeLevel: Token does not exist");
        Level[tokenId] += 1;
    }

    function _baseURI() internal view override returns(string memory)
    {
        return BaseURI;
    }

}