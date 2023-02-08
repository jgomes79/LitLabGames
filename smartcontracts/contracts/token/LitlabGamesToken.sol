// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LitlabGamesToken is ERC20 {

    constructor() ERC20("LitlabToken", "LITT") {  
        _mint(msg.sender, 3000000000 * 10 ** 18);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
