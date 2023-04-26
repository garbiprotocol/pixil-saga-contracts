// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IWhiteList.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Treasury is Ownable, Pausable
{
    using SafeMath for uint256;

    IWhiteList public WhiteList;
    IERC20 public CyberCreditToken;
    IERC20 public veGRBToken;

    uint256 public MaxLengthPacketsVeGRB;
    mapping(uint256 => uint256) public PacketsVeGRB;

    uint256 public ConversionRate;

    event OnBuyPacket(address user, uint256 indexPacket, uint256 amountTokenInputput, uint256 amountTokenOutput);

    constructor(IERC20 cyberCreditTokenContract, IERC20 veGRBTokenContract)
    {
        CyberCreditToken = cyberCreditTokenContract;
        veGRBToken = veGRBTokenContract;

        //test
        ConversionRate = 49152;      // 1 veGRB = 49152 cc

        MaxLengthPacketsVeGRB  = 4;
        PacketsVeGRB[0] = 10e18;
        PacketsVeGRB[1] = 50e18;
        PacketsVeGRB[2] = 100e18;
        PacketsVeGRB[3] = 200e18;

    }

    modifier onlyWhiteList()
    {
        if(msg.sender != tx.origin)
        {
            require(WhiteList.whitelisted(msg.sender) == true, "invalid whitelist");
        }
        _;
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

    function SetConversionRate(uint256 newConversionRate) public onlyOwner
    {
        ConversionRate = newConversionRate;
    }

    function BuyPacket(uint256 indexPacket) public whenNotPaused onlyWhiteList
    {
        address user = _msgSender();
        require(indexPacket >= 0 && indexPacket < MaxLengthPacketsVeGRB, "Error BuyPacket: Invalid Packet");

        uint256 amountTokenOutput = PacketsVeGRB[indexPacket];
        uint256 amountTokenInput = amountTokenOutput.mul(ConversionRate);

        require(CyberCreditToken.balanceOf(user) >= amountTokenInput, "Error BuyPacket: Invalid Balance CyberCredit in wallet");
        require(amountTokenOutput <= veGRBToken.balanceOf(address(this)),  "Error BuyPacket: Invalid Balance veGRB in Treasury");

        CyberCreditToken.transferFrom(user, address(this), amountTokenInput);

        veGRBToken.transfer(user, amountTokenOutput);

        emit OnBuyPacket(user, indexPacket, amountTokenInput, amountTokenOutput);
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