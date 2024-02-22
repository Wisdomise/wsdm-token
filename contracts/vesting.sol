// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.18;
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet {
    uint64[] vestingReleaseTimestamp;
    uint32 tgeReleasePercentage;

    constructor(
        address beneficiary,
        uint32 _tgeReleasePercentage,
        uint64[] memory _vestingReleaseTimestamp
    )
        VestingWallet(
            beneficiary,
            _vestingReleaseTimestamp[0],
            _vestingReleaseTimestamp[_vestingReleaseTimestamp.length - 1] - _vestingReleaseTimestamp[0]
        )
    {
        _setTgeReleasePercentage(_tgeReleasePercentage);
        vestingReleaseTimestamp = _vestingReleaseTimestamp;
    }

    receive() external payable override {
        revert("Not Allowed");
    }

    function _setTgeReleasePercentage(uint32 _tgeReleasePercentage) private {
        require(_tgeReleasePercentage <= 10 ** 6, "Vesting: tge release should not be more than 100%");
        tgeReleasePercentage = _tgeReleasePercentage;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view override returns (uint256) {
        if (timestamp < start()) {
            return (totalAllocation * tgeReleasePercentage) / 10 ** 6;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            uint256 tge_round_release = (totalAllocation * tgeReleasePercentage) / 10 ** 6;
            uint256 current_round_release = (((totalAllocation - tge_round_release) * getVestingRound(timestamp)) /
                vestingReleaseTimestamp.length);
            return tge_round_release + current_round_release;
        }
    }

    function getVestingRound(uint64 timestamp) public view returns (uint vesting_round) {
        for (uint i = vestingReleaseTimestamp.length; i > 0; i--) {
            if (timestamp > vestingReleaseTimestamp[i - 1]) {
                vesting_round = i;
                break;
            }
        }
        return vesting_round;
    }
}
