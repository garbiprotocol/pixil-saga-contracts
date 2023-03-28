// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockGRB is ERC20Burnable, Ownable
{
    constructor() ERC20("Mock GRB", "MGRB"){
        _mint(_msgSender(), 1000e18);
    }

    function Mint(address to) public 
    {
        _mint(to, 100e18);
    }
}