// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.18;

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

    mapping(address => uint256) angelInvestorShares;
    mapping(address => uint256) strategicInvestorShares;

    event InvestorInserted(address indexed investor, uint256 balance, InvestorType investorType);
    event InvestorMigrated(address indexed investor, uint256 totalShares);

    constructor(
        IERC20 _twsdmTokenAddress,
        ITokenDistributor _angelDistributorContract,
        ITokenDistributor _strategicDistributorContract
    )
        validAddress(address(_twsdmTokenAddress))
        validAddress(address(_angelDistributorContract))
        validAddress(address(_strategicDistributorContract))
    {
        twsdmTokenAddress = _twsdmTokenAddress;
        angelDistributorContract = _angelDistributorContract;
        strategicDistributorContract = _strategicDistributorContract;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "TokenMigration: input address should not be address zero");
        _;
    }

    function addBulkAngelInvestor(address[] memory investors, uint256[] memory balances) public onlyOwner {
        _addBulkInvestor(investors, balances, InvestorType.ANGEL);
    }

    function addBulkStrategicInvestor(address[] memory investors, uint256[] memory balances) public onlyOwner {
        _addBulkInvestor(investors, balances, InvestorType.STRATEGIC);
    }

    function migrate() public {
        uint256 angelRoundShares = angelInvestorShares[msg.sender];
        uint256 strategicRoundShares = strategicInvestorShares[msg.sender];
        uint256 totalShares = angelRoundShares + strategicRoundShares;
        require(totalShares > 0, "TokenMigration: zero total investor shares");

        uint256 balance = twsdmTokenAddress.balanceOf(msg.sender);
        require(balance >= totalShares, "TokenMigration: twsdm balance is less than investor shares");

        angelInvestorShares[msg.sender] = 0;
        strategicInvestorShares[msg.sender] = 0;

        _burnTwsdm(totalShares);

        _registerPayeeInDistributor(angelDistributorContract, msg.sender, angelRoundShares);
        _registerPayeeInDistributor(strategicDistributorContract, msg.sender, strategicRoundShares);

        emit InvestorMigrated(msg.sender, totalShares);
    }

    function getAngelInvestorBalance(address investor) public view returns (uint256) {
        return angelInvestorShares[investor];
    }

    function getStrategicInvestorBalance(address investor) public view returns (uint256) {
        return strategicInvestorShares[investor];
    }

    function _addBulkInvestor(
        address[] memory investors,
        uint256[] memory balances,
        InvestorType investorType
    ) private {
        require(investors.length == balances.length, "TokenMigration: investors and balances length does not match");
        require(investors.length > 0, "TokenMigration: no investor added");

        for (uint256 i = 0; i < investors.length; ) {
            _addInvestor(investors[i], balances[i], investorType);
            unchecked {
                i++;
            }
        }
    }

    function _addInvestor(address investor, uint256 balance, InvestorType investorType) private {
        require(investor != address(0), "TokenMigration: investor should not be address zero");

        if (investorType == InvestorType.ANGEL) {
            angelInvestorShares[investor] = balance;
        } else if (investorType == InvestorType.STRATEGIC) {
            strategicInvestorShares[investor] = balance;
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
