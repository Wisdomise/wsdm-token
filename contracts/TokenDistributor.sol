// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenDistributor.sol";

// This contract is heavily inspired by openzeppelin PaymentSplitter "@openzeppelin/contracts/finance/PaymentSplitter.sol"

contract TokenDistributor is ITokenDistributor, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable wsdmTokenAddress;
    address public immutable wisdomiseReserve;
    uint256 public immutable totalShares;
    uint64 public immutable claimDeadline;

    address public tokenMigrationContract;

    uint64 constant MIGRATION_DEADLINE = 1735689600; // January 1, 2025 0:00:00

    uint256 private _totalAllocatedShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    event MigrationContractSet(address indexed account);
    event PayeeAdded(address indexed account, uint256 shares);
    event PaymentReleased(address indexed to, uint256 amount);

    constructor(
        IERC20 _wsdmTokenAddress,
        address _wisdomiseReserve,
        uint256 _totalShares,
        uint64 _claimDeadline
    ) validAddress(address(_wsdmTokenAddress)) validAddress(_wisdomiseReserve) {
        wsdmTokenAddress = _wsdmTokenAddress;
        wisdomiseReserve = _wisdomiseReserve;
        totalShares = _totalShares;
        claimDeadline = _claimDeadline;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "TokenDistributor: input address should not be address zero");
        _;
    }

    modifier onlyMigrationContract() {
        require(msg.sender == tokenMigrationContract, "TokenDistributor: only migration contract");
        _;
    }

    function setTokenMigrationContractAddress(
        address tokenMigrationContract_
    ) public onlyOwner validAddress(tokenMigrationContract_) {
        tokenMigrationContract = tokenMigrationContract_;
        emit MigrationContractSet(tokenMigrationContract_);
    }

    function release(address account) public virtual {
        require(_shares[account] > 0, "TokenDistributor: account has no shares");

        uint256 payment = releasable(account);

        require(payment > 0, "TokenDistributor: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

        wsdmTokenAddress.safeTransfer(account, payment);
        emit PaymentReleased(account, payment);
    }

    function addPayee(address account, uint256 shares) public onlyMigrationContract {
        _addPayee(account, shares);
    }

    function addBulkPayeeByOwner(address[] memory accounts, uint256[] memory shares) public onlyOwner {
        require(accounts.length == shares.length, "TokenDistributor: accounts and shares length does not match");
        require(accounts.length > 0, "TokenDistributor: no payee added");

        for (uint256 i = 0; i < accounts.length; ) {
            _addPayee(accounts[i], shares[i]);
            unchecked {
                i++;
            }
        }
    }

    function claimNonMigratedSharesAfterDeadline() public {
        require(block.timestamp > MIGRATION_DEADLINE, "TokenDistributor: not after migration deadline");
        require(totalShares > totalAllocatedShares(), "TokenDistributor: no non-migrated share left");
        _addPayee(wisdomiseReserve, totalShares - totalAllocatedShares());
    }

    function claimNonClaimedTokensAfterDeadline() public {
        require(block.timestamp > claimDeadline, "TokenDistributor: not after claim deadline");

        uint256 remainingBalance = wsdmTokenAddress.balanceOf(address(this));
        require(remainingBalance > 0, "TokenDistributor: no non-claimed token left");

        wsdmTokenAddress.safeTransfer(wisdomiseReserve, remainingBalance);
        emit PaymentReleased(wisdomiseReserve, remainingBalance);
    }

    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = wsdmTokenAddress.balanceOf(address(this)) + totalReleased();
        return _pendingPayment(account, totalReceived, getAccountReleased(account));
    }

    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / totalShares - alreadyReleased;
    }

    function _addPayee(address account, uint256 shares) private validAddress(account) {
        require(shares > 0, "TokenDistributor: shares are 0");

        _totalAllocatedShares = _totalAllocatedShares + shares;
        require(_totalAllocatedShares <= totalShares, "TokenDistributor: shares are over total shares");

        _shares[account] = _shares[account] + shares;
        emit PayeeAdded(account, shares);
    }

    function totalAllocatedShares() public view returns (uint256) {
        return _totalAllocatedShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function getAccountShares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function getAccountReleased(address account) public view returns (uint256) {
        return _released[account];
    }
}
