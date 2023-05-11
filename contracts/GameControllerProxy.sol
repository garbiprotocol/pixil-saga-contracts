// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGameController.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20
{
    function deposit() external payable;

    function depositTo(address account) external payable;
}

contract GameControllerProxy is Ownable
{
    using SafeMath for uint256;

    IWETH public WETH;
    IGameController GameControllerContract;

    event OnMintHeroNFTWithETH(address user, uint256 amountETH);

    constructor(IWETH wethAddress, IGameController gameControllerAddress)
    {
        WETH = wethAddress;
        GameControllerContract = gameControllerAddress;

        ApproveToGameController();
    }

    function ApproveToGameController() public  
    {
        WETH.approve(address(GameControllerContract), 10000000000e18);
    }

    function MintHeroNFTWithETH(uint256 teamId) public payable
    {
        address user = _msgSender();

        // validate 
        uint256 priceCreditMint = (GameControllerContract.ListAddressMintFree(user) == true) 
                    ? 0 : GameControllerContract.PriceCreditMint();
        
        require(msg.value >= priceCreditMint, "Error MintHeroNFTWithETH: invalid value ETH");

        // Mint heroNFT
        if(priceCreditMint == 0)
        {
            GameControllerContract.MintHeroNFT(user, teamId);
        }
        else
        {
            uint256 oldBalanceWETHContract = WETH.balanceOf(address(this));
            WETH.deposit{value: priceCreditMint}();
            require(oldBalanceWETHContract.add(priceCreditMint) >= WETH.balanceOf(address(this)), "Error: Swap ETH to WETH");
        
            GameControllerContract.MintHeroNFT(user, teamId);
        }
        
        uint256 repayETH = msg.value.sub(priceCreditMint);
        if(repayETH > 0) 
        {
            (bool success, ) = user.call{value: repayETH}("");
            require(success, "Error repayETH");
        }
        
        emit OnMintHeroNFTWithETH(user, priceCreditMint);
    }
}