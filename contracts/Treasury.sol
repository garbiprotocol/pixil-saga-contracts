// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Treasury is Ownable, Pausable
{
    using SafeMath for uint256;

    IERC20 public CyberCreditToken;
    IERC20 public veGRBToken;

    uint256 public MaxLengthPacketsVeGRB;
    mapping(uint256 => uint256) public PacketsVeGRB;

    event OnBuyPacket(address user, uint256 indexPacket, uint256 amountTokenInputput);

    constructor(IERC20 cyberCreditTokenContract, IERC20 veGRBTokenContract)
    {
        CyberCreditToken = cyberCreditTokenContract;
        veGRBToken = veGRBTokenContract;

        //test
        MaxLengthPacketsVeGRB  = 4;
        PacketsVeGRB[0] = 10e18;
        PacketsVeGRB[1] = 50e18;
        PacketsVeGRB[2] = 200e18;
        PacketsVeGRB[3] = 500e18;
    }

    function SetCyberCreditTokenContract(IERC20 cyberCreditTokenContract) public onlyOwner 
    {
        CyberCreditToken = cyberCreditTokenContract;
    }

    function SetVeGRBTokenContract(IERC20 veGRBTokenContract) public onlyOwner
    {
        veGRBToken = veGRBTokenContract;
    }

    function SetMaxLengthPacketsVeGRB(uint256 value) public onlyOwner 
    {
        MaxLengthPacketsVeGRB = value;
    }

    function SetAmountPacketsVeGRB(uint256 indexPacket, uint256 amountPacket) public onlyOwner 
    {
        PacketsVeGRB[indexPacket] = amountPacket;
    }

    function BuyPacket(uint256 indexPacket) public
    {
        address user = _msgSender();
        uint256 amountTokenInput = PacketsVeGRB[indexPacket];
        require(amountTokenInput != 0, "Error BuyPacket: Invalid Packet");
        require(CyberCreditToken.balanceOf(user) >= amountTokenInput, "Error BuyPacket: Invalid Balance CyberCredit");
        require(amountTokenInput <= veGRBToken.balanceOf(address(this)),  "Error BuyPacket: Invalid Balance veGRB in Treasury");

        CyberCreditToken.transferFrom(user, address(this), amountTokenInput);

        veGRBToken.transfer(user, amountTokenInput);

        emit OnBuyPacket(user, indexPacket, amountTokenInput);
    }

    function GetData() public view returns(uint256 balanceTreasury, uint256[] memory amountPacket)
    {
        balanceTreasury = veGRBToken.balanceOf(address(this));
        amountPacket = new uint256[](MaxLengthPacketsVeGRB);

        for(uint256 indexPacket = 0; indexPacket < MaxLengthPacketsVeGRB; indexPacket++)
        {
            amountPacket[indexPacket] = PacketsVeGRB[indexPacket];
        }
    }

}