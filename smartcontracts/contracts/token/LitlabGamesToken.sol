// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC20, ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title LITLABGAMES ERC20 token
/// @notice ERC20 token with gasless and burn options
contract LitlabGamesToken is ERC20Permit {

    constructor() ERC20("LitlabToken", "LITT") ERC20Permit("LitlabToken") {  
        _mint(msg.sender, 3000000000 * 10 ** 18);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
