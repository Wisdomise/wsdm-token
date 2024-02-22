// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Locking is ERC20, Pausable, Ownable {
    using SafeERC20 for IERC20;

    struct LockInfo {
        uint256 startTimestamp;
        bool hasUnlockedBefore;
        uint64 configId;
    }
    struct UnlockInfo {
        uint256 unlockAmount;
        uint256 withdrawTimestamp;
        uint256 penaltyAmount;
    }
    address public penaltyTreasury;
    IERC20 public immutable wsdmTokenAddress;
    uint256 constant MONTHLY_PENALTY_INTERVAL = 30 days;
    uint256 constant RESCUE_WAIT_PERIOD = 7 days;
    uint256 public freeUnlockDuration;
    bool public immediateFreeExit;
    address public pauser;
    uint256 public numberOfFreeTrialPeriod;
    uint256 public pauseTimestamp;
    uint64 public configCounter;

    mapping(address => LockInfo) private _lockedUsers;
    mapping(address => UnlockInfo) private _unlockedUsers;
    mapping(uint64 => uint64[12]) private monthlyPenaltyConfigs;
    mapping(uint64 => uint256) private withdrawPeriodConfigs;

    event TokenLocked(address indexed owner, uint256 amount);
    event TokenUnlocked(address indexed owner, uint256 amount);
    event ImmediateFreeExitSet(bool status);
    event Withdrew(address indexed owner, uint256 amount, uint256 penalty);
    event RescuedFunds(address indexed owner, uint256 amount);
    event NewConfigSet(uint64 configCounter);
    event FreeTrialPeriodSet(uint256 numberOfFreeTrialPeriod);
    event FreeUnlockDurationSet(uint256 freeUnlockDurationInSecond);
    event PenaltyTreasurySet(address penaltyTreasury);
    event PauserSet(address pauser);

    modifier onlyPauser() {
        require(msg.sender == pauser, "Locking: caller is not the pauser");
        _;
    }

    constructor(
        address _pauser,
        address _penaltyTreasury,
        IERC20 _wsdmTokenAddress,
        uint64[12] memory _monthlyPenaltyFees,
        uint256 _withdrawPeriod,
        uint256 _freeUnlockDurationInSecond,
        uint8 _numberOfFreeTrialPeriod
    ) ERC20("Locked Wisdomise", "lcWSDM") {
        _setPauser(_pauser);
        _setPenaltyTreasury(_penaltyTreasury);
        _setConfig(_monthlyPenaltyFees, _withdrawPeriod);
        _setFreeUnlockDuration(_freeUnlockDurationInSecond);
        _setNumberOfFreeTrialPeriod(_numberOfFreeTrialPeriod);
        wsdmTokenAddress = _wsdmTokenAddress;
    }

    function setNumberOfFreeTrialPeriod(uint256 numberOfFreeTrialPeriod_) public onlyOwner {
        _setNumberOfFreeTrialPeriod(numberOfFreeTrialPeriod_);
    }

    function _setNumberOfFreeTrialPeriod(uint256 _numberOfFreeTrialPeriod) private {
        numberOfFreeTrialPeriod = _numberOfFreeTrialPeriod;
        emit FreeTrialPeriodSet(_numberOfFreeTrialPeriod);
    }

    function setFreeUnlockDuration(uint256 freeUnlockDurationInSecond_) public onlyOwner {
        _setFreeUnlockDuration(freeUnlockDurationInSecond_);
    }

    function _setFreeUnlockDuration(uint256 _freeUnlockDurationInSecond) private {
        freeUnlockDuration = _freeUnlockDurationInSecond;
        emit FreeUnlockDurationSet(_freeUnlockDurationInSecond);
    }

    function setWithdrawPeriod(uint256 withdrawPeriod) public onlyOwner {
        require(
            withdrawPeriodConfigs[configCounter] != withdrawPeriod,
            "Locking: New withdraw period must be different from the previous one"
        );
        _setConfig(monthlyPenaltyConfigs[configCounter], withdrawPeriod);
    }

    function setMonthlyPenaltyFees(uint64[12] memory monthlyPenaltyFees) public onlyOwner {
        require(
            !equalsArray(monthlyPenaltyConfigs[configCounter], monthlyPenaltyFees),
            "Locking: New monthly penalty fee must be different from the previous"
        );

        _setConfig(monthlyPenaltyFees, withdrawPeriodConfigs[configCounter]);
    }

    function _setConfig(uint64[12] memory _monthlyPenaltyFees, uint256 _withdrawPeriod) private {
        for (uint8 i = 0; i < 12; ) {
            require(_monthlyPenaltyFees[i] <= 10 ** 6, "Locking: penalty fee should not be more than 100%");
            unchecked {
                i++;
            }
        }
        configCounter += 1;
        monthlyPenaltyConfigs[configCounter] = _monthlyPenaltyFees;
        withdrawPeriodConfigs[configCounter] = _withdrawPeriod;
        emit NewConfigSet(configCounter);
    }

    function setImmediateFreeExit(bool immediateFreeExit_) external onlyOwner {
        immediateFreeExit = immediateFreeExit_;
        emit ImmediateFreeExitSet(immediateFreeExit_);
    }

    function getLockedUsers(address user) public view returns (LockInfo memory) {
        return _lockedUsers[user];
    }

    function getWithdrawPeriodConfig(uint64 configId) public view returns (uint256) {
        return withdrawPeriodConfigs[configId];
    }

    function getMonthlyPenaltyConfigs(uint64 configId) public view returns (uint64[12] memory) {
        return monthlyPenaltyConfigs[configId];
    }

    function getUserUnLockedInfo(address user) public view returns (UnlockInfo memory) {
        return _unlockedUsers[user];
    }

    function setPenaltyTreasury(address penaltyTreasury_) public onlyOwner {
        _setPenaltyTreasury(penaltyTreasury_);
    }

    function _setPenaltyTreasury(address _penaltyTreasury) private {
        penaltyTreasury = _penaltyTreasury;
        emit PenaltyTreasurySet(_penaltyTreasury);
    }

    function setPauser(address pauser_) public onlyOwner {
        _setPauser(pauser_);
    }

    function _setPauser(address _pauser) private {
        pauser = _pauser;
        emit PauserSet(_pauser);
    }

    function lock(uint256 amount) public whenNotPaused {
        _lock(amount);
    }

    function lockWithPermit(
        uint256 amount,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused {
        try
            IERC20Permit(address(wsdmTokenAddress)).permit(msg.sender, address(this), value, deadline, v, r, s)
        {} catch {}
        _lock(amount);
    }

    function unlock() public whenNotPaused {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0, "Locking: You cannot unlock tokens as you don't have any locked tokens");
        require(
            _unlockedUsers[msg.sender].unlockAmount == 0,
            "Locking: You are not allowed to unlock a new one before the previous one is completed"
        );
        _unlockedUsers[msg.sender].penaltyAmount = calculatePenalty(msg.sender, balance, block.timestamp);
        _unlockedUsers[msg.sender].withdrawTimestamp =
            block.timestamp +
            withdrawPeriodConfigs[_lockedUsers[msg.sender].configId];

        _lockedUsers[msg.sender].startTimestamp = 0;
        _lockedUsers[msg.sender].hasUnlockedBefore = true;
        _lockedUsers[msg.sender].configId = 0;

        _unlockedUsers[msg.sender].unlockAmount = balance;

        _burn(msg.sender, balance);
        emit TokenUnlocked(msg.sender, balance);
        if (_unlockedUsers[msg.sender].withdrawTimestamp == block.timestamp || immediateFreeExit) withdraw();
    }

    function cancelUnlock() public whenNotPaused {
        uint256 _unlockAmount = _unlockedUsers[msg.sender].unlockAmount;
        require(_unlockAmount > 0, "Locking: You cannot cancel unlock as you don't have any locked tokens");
        if (_lockedUsers[msg.sender].startTimestamp == 0) {
            _lockedUsers[msg.sender].startTimestamp = block.timestamp;
            _lockedUsers[msg.sender].configId = configCounter;
        }

        delete _unlockedUsers[msg.sender];

        _mint(msg.sender, _unlockAmount);
        emit TokenLocked(msg.sender, _unlockAmount);
    }

    function withdraw() public whenNotPaused {
        require(
            _unlockedUsers[msg.sender].unlockAmount > 0,
            "Locking: You cannot withdraw without unlocking your tokens"
        );
        require(
            _unlockedUsers[msg.sender].withdrawTimestamp <= block.timestamp || immediateFreeExit,
            "Locking: Unable to withdraw, please wait until your withdrawal is released"
        );
        uint256 balance = _unlockedUsers[msg.sender].unlockAmount;
        uint256 _penalty = _unlockedUsers[msg.sender].penaltyAmount;

        delete _unlockedUsers[msg.sender];

        if (_penalty > 0) wsdmTokenAddress.safeTransfer(penaltyTreasury, _penalty);
        wsdmTokenAddress.safeTransfer(msg.sender, (balance - _penalty));
        emit Withdrew(msg.sender, balance, _penalty);
    }

    function emergencyRescueFunds(uint256 amount) public whenPaused onlyOwner {
        require(block.timestamp >= pauseTimestamp + RESCUE_WAIT_PERIOD, "Locking: rescue wait period is not over");
        require(amount <= wsdmTokenAddress.balanceOf(address(this)), "Locking: rescue amount exceeds contract balance");
        wsdmTokenAddress.safeTransfer(msg.sender, amount);
        emit RescuedFunds(msg.sender, amount);
    }

    function calculatePenalty(address locker, uint256 balance, uint256 unlockTimestamp) public view returns (uint256) {
        if (immediateFreeExit) {
            return 0;
        }
        return (balance * calculatePenaltyFee(locker, unlockTimestamp)) / 10 ** 6;
    }

    function calculatePenaltyFee(address locker, uint256 unlockTimestamp) public view returns (uint256) {
        uint256 _lockTimestamp = _lockedUsers[locker].startTimestamp;
        uint256 _currentStep = (unlockTimestamp - _lockTimestamp) / MONTHLY_PENALTY_INTERVAL;

        uint256 _penaltyFee;

        uint256 _completeYears = _currentStep / 12;
        uint256 _startFreeDays = _completeYears * (360 days) + _lockTimestamp;
        uint256 _endFreeDays = _startFreeDays + freeUnlockDuration;

        _currentStep = _currentStep % 12;

        if (_completeYears > 0 && _startFreeDays < unlockTimestamp && unlockTimestamp < _endFreeDays) {
            _penaltyFee = 0;
        } else if (
            _completeYears == 0 &&
            _lockedUsers[locker].hasUnlockedBefore == false &&
            _currentStep < numberOfFreeTrialPeriod
        ) {
            _penaltyFee = 0;
        } else {
            _penaltyFee = monthlyPenaltyConfigs[_lockedUsers[locker].configId][_currentStep];
        }

        return _penaltyFee;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function pause() public onlyPauser {
        pauseTimestamp = block.timestamp;
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function _lock(uint256 _amount) internal virtual {
        require(_amount > 0, "Locking: The locking value must be greater than zero");

        if (_lockedUsers[msg.sender].startTimestamp == 0) {
            _lockedUsers[msg.sender].startTimestamp = block.timestamp;
            _lockedUsers[msg.sender].configId = configCounter;
        }
        wsdmTokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        emit TokenLocked(msg.sender, _amount);
    }

    function _transfer(address, address, uint256) internal pure override {
        revert("Locking: Transfers are not allowed");
    }

    function equalsArray(uint64[12] memory firstArray, uint64[12] memory secondArray) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(firstArray)) == keccak256(abi.encodePacked(secondArray)));
    }
}
