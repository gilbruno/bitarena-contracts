// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {ERC20Pausable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AddressZeroError} from "./BitarenaFactoryErrors.sol";

contract BitarenaToken is ERC20, ERC20Pausable, Ownable {

    constructor() ERC20("BitarenaToken", "BART") Ownable(msg.sender) payable
    {
        uint totalSupply = 100000000 * 10 ** decimals();
        _mint(msg.sender, totalSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal  override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}