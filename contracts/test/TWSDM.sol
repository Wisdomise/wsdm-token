// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TWSDM is ERC20, Ownable {
    bool public transferable;
    address public immutable treasury;
    uint256 constant initialAmount = 200_000_000;

    mapping(address => bool) public AuthorizedAddresses;

    event AuthorizedAddressesChanged(address _newAuthorizedAddress, bool _status);
    event transferableChanged(bool _transferable);

    //test
    constructor(
        address _treasury
    ) ERC20("Temporary Wisdomise", "tWSDM") {
        treasury = _treasury;
        _mint(treasury, initialAmount * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function changeTransferable(bool _transferable) public onlyOwner {
        require(
            transferable != _transferable,
            "TWSDM: This input is equal to the current value"
        );
        transferable = _transferable;
        emit transferableChanged(_transferable);
    }

    function addOrRemoveAuthorizedAddresses(
        address[] memory _newAuthorizedAddresses,
        bool _status
    ) public onlyOwner {
        for (uint i =0 ; i<_newAuthorizedAddresses.length; i++)
            _setAuthorizedAddress(_newAuthorizedAddresses[i], _status);
    }

    function _setAuthorizedAddress(
        address _newAuthorizedAddress,
        bool _status
    ) private {
        require(
            AuthorizedAddresses[_newAuthorizedAddress] == !_status,
            "TWSDM: This input is equal to the current value"
        );
        AuthorizedAddresses[_newAuthorizedAddress] = _status;
        emit AuthorizedAddressesChanged(_newAuthorizedAddress, _status);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0) && transferable == false) {
            require(
                AuthorizedAddresses[msg.sender] == true,
                "TWSDM: You are not allowed to transfer this token!"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
