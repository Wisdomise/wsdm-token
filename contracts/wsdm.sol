// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract WSDM is ERC20, ERC20Permit {
    uint256 constant TOTAL_SUPPLY = 1_000_000_000;

    constructor(address reserve) ERC20("Wisdomise", "WSDM") ERC20Permit("Wisdomise") {
        _mint(reserve, TOTAL_SUPPLY * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
