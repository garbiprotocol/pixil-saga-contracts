// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockVeGRB is Ownable, ERC20
{
    mapping(address => bool) public isRecieve;

    constructor() ERC20("Mock veGRB", "MveGRB")
    {
        _mint(_msgSender(), 1000e18);
    }

    event EventClaimToken(address addressReceive , uint256 amount);

    function SetRecieveAddress(address recieveAddress) public onlyOwner
    {
        isRecieve[recieveAddress] = true;
    }

    function DeleteRecieveAddress(address addressRecieve) public onlyOwner
    {
        require(isRecieve[addressRecieve] == true, "invalid address");
        isRecieve[addressRecieve] = false;
    }

    function ClaimToken(address addressRecieve, uint256 amount) public onlyOwner
    {
        require(isRecieve[addressRecieve] == true, "invalids address");
        require(amount > 0, "invalid amount");
        _mint(addressRecieve, amount);

        emit EventClaimToken(addressRecieve, amount);
    }

}
