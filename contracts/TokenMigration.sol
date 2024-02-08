// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenDistributor.sol";

contract TokenMigration is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable twsdmTokenAddress;
    ITokenDistributor public immutable angelDistributorContract;
    ITokenDistributor public immutable strategicDistributorContract;

    address constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    enum InvestorType {
        ANGEL,
        STRATEGIC
    }

    mapping(address => uint256) angelInvestors;
    mapping(address => uint256) strategicInvestors;

    event InvestorInserted(address indexed investor, uint256 balance, InvestorType investorType);
    event InvestorMigrated(address indexed investor);

    constructor(
        IERC20 _twsdmTokenAddress,
        ITokenDistributor _angelDistributorContract,
        ITokenDistributor _strategicDistributorContract
    ) {
        twsdmTokenAddress = _twsdmTokenAddress;
        angelDistributorContract = _angelDistributorContract;
        strategicDistributorContract = _strategicDistributorContract;
    }

    function addBulkAngelInvestor(address[] memory investors, uint256[] memory balances) public onlyOwner {
        _addBulkInvestor(investors, balances, InvestorType.ANGEL);
    }

    function addBulkStrategicInvestor(address[] memory investors, uint256[] memory balances) public onlyOwner {
        _addBulkInvestor(investors, balances, InvestorType.STRATEGIC);
    }

    function migrate() public {
        uint256 balance = twsdmTokenAddress.balanceOf(msg.sender);
        require(balance > 0, "TokenMigration: zero twsdm balance");

        uint256 angelInvestorShares = angelInvestors[msg.sender];
        uint256 strategicInvestorShares = strategicInvestors[msg.sender];
        require(
            balance == angelInvestorShares + strategicInvestorShares,
            "TokenMigration: twsdm balance does not match with investor shares"
        );

        angelInvestors[msg.sender] = 0;
        strategicInvestors[msg.sender] = 0;

        _burnTwsdm(balance);

        _registerPayeeInDistributor(angelDistributorContract, msg.sender, angelInvestorShares);
        _registerPayeeInDistributor(strategicDistributorContract, msg.sender, strategicInvestorShares);

        emit InvestorMigrated(msg.sender);
    }

    function getAngelInvestorBalance(address investor) public view returns (uint256) {
        return angelInvestors[investor];
    }

    function getStrategicInvestorBalance(address investor) public view returns (uint256) {
        return strategicInvestors[investor];
    }

    function _addBulkInvestor(
        address[] memory investors,
        uint256[] memory balances,
        InvestorType investorType
    ) private {
        require(investors.length == balances.length, "TokenMigration: investors and balances length does not match");
        require(investors.length > 0, "TokenMigration: no investor added");

        for (uint256 i = 0; i < investors.length; i++) {
            _addInvestor(investors[i], balances[i], investorType);
        }
    }

    function _addInvestor(address investor, uint256 balance, InvestorType investorType) private {
        require(investor != address(0), "TokenMigration: investor should not be address zero");

        if (investorType == InvestorType.ANGEL) {
            angelInvestors[investor] = balance;
        } else if (investorType == InvestorType.STRATEGIC) {
            strategicInvestors[investor] = balance;
        }

        emit InvestorInserted(investor, balance, investorType);
    }

    function _burnTwsdm(uint256 balance) private {
        twsdmTokenAddress.safeTransferFrom(msg.sender, BURN_ADDRESS, balance);
    }

    function _registerPayeeInDistributor(
        ITokenDistributor distributorContract,
        address account,
        uint256 shares
    ) private {
        if (shares > 0) {
            distributorContract.addPayee(account, shares);
        }
    }
}
