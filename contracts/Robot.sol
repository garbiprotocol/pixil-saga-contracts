// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// NFT
contract Robot is ERC721Enumerable, Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private TokenId;

    bool public EnableSystem;
    mapping(address => bool) public Miner;

    string public BaseURI;

    event OnMintNFT(address from, address to, uint256 tokenId);

    mapping(uint256 => uint256) public Level;

    modifier IsEnableSystem()
    {
        require(EnableSystem == true, "System paused");
        _;
    }

    constructor(
        string memory tokenName, string memory tokenSysbol
        ) ERC721 (tokenName, tokenSysbol)
    {
        EnableSystem = true;
    }

    function SetPauseSystem() public onlyOwner 
    {
        EnableSystem = false;
    }

    function SetEnableSystem() public onlyOwner
    {
        EnableSystem = true;
    }

    function SetEnableMiner(address miner) public onlyOwner IsEnableSystem 
    {
        require(Miner[miner] == false, "Error SetEnableMiner: Invalid miner");
        Miner[miner] = true;
    }

    function SetDisableMiner(address miner) public onlyOwner IsEnableSystem
    {
        require(Miner[miner] == true, "Error SetDisableMiner: Invalid miner");
        Miner[miner] = false;
    }

    function SetBaseURI(string memory baseURI) public onlyOwner 
    {
        require(bytes(baseURI).length > 0, "Error SetBaseURI: Invalid baseURI");
        BaseURI = baseURI;
    }

    function Mint(address to) public IsEnableSystem returns(uint256)
    {
        require(Miner[msg.sender] == true, "Error Mint: Invalid miner");
        TokenId.increment();
        uint256 newTokenId = TokenId.current();
        _safeMint(to, newTokenId);
        Level[newTokenId] = 0;

        emit OnMintNFT(msg.sender, to, newTokenId);

        return newTokenId;
    }

    function Burn(uint256 tokenId) public IsEnableSystem virtual
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function UpgrateLevel(uint256 tokenId) public IsEnableSystem
    {
        require(Miner[msg.sender] == true, "Error UpgrateLevel");
        Level[tokenId] += 1;
    }

    function _baseURI() internal view override returns(string memory)
    {
        return BaseURI;
    }
    
}