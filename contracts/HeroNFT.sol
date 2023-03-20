// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// NFT
contract HeroNFT is ERC721Enumerable, Ownable, Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter private HeroId;

    string public BaseURI;

    IERC20 public ERC20CreditToken;

    uint256 public PriceCreditMint;

    mapping(uint256 => uint256) public TeamId;

    event OnMintNFT(address from, address to, uint256 HeroId);

    constructor(
        string memory tokenName, string memory tokenSymbol,
        IERC20 erc20CreditToken
        ) ERC721 (tokenName, tokenSymbol) 
    {
        ERC20CreditToken = erc20CreditToken;
        PriceCreditMint = 1e18;
    }

    function SetPauseSystem() public onlyOwner 
    {
        _pause();
    }

    function SetEnableSystem() public onlyOwner
    {
        _unpause();
    }

    function SetPriceCreditMint(uint256 value) public onlyOwner
    {
        PriceCreditMint = value;
    }

    function SetBaseURI(string memory baseURI) public onlyOwner 
    {
        require(bytes(baseURI).length > 0, "Error SetBaseURI: Invalid baseURI");
        BaseURI = baseURI;
    }

    function Mint(uint256 teamId) public whenNotPaused returns(uint256)
    {
        address to = _msgSender();
        require(ERC20CreditToken.balanceOf(to) >= PriceCreditMint, "Error Mint: Invalid balance");
        ERC20CreditToken.transferFrom(to, address(this), PriceCreditMint);
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

    function WidthdrawCredit() public onlyOwner 
    {
        address to = owner();
        ERC20CreditToken.transfer(to, ERC20CreditToken.balanceOf(address(this)));
    }
}