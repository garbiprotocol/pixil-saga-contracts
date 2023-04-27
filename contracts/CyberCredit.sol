// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberCredit is ERC20Burnable, Ownable 
{
    mapping(address => bool) public isRecieve;

    constructor() ERC20("CyberCredit", "Cyber") {}

    event EventClaimToken(address addressReceive , uint256 amount);

    function SetRecieveAddress(address recieveAddress) public onlyOwner
    {
        isRecieve[recieveAddress] = true;
    }

    function DeleteRecieveAddress(address addressRecieve) public onlyOwner
    {
        require(isRecieve[addressRecieve] == true, "invalid address");
        delete isRecieve[addressRecieve];
    }

    function ClaimToken(address addressRecieve, uint256 amount) public onlyOwner
    {
        require(isRecieve[addressRecieve] == true, "Error Claim CyberCredit: invalid address");
        require(amount > 0, "Error Claim CyberCredit: invalid amount");
        _mint(addressRecieve, amount);

        emit EventClaimToken(addressRecieve, amount);
    }

}
