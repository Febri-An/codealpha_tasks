// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

contract CryptoLock {

    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Deposit) private deposits;

    event Deposited(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount);

    // ─── Deposit ───────────────────────────────────────────────
    function deposit(uint256 _lockDurationInSeconds) external payable {
        require(msg.value > 0, "Must deposit some Ether");
        require(_lockDurationInSeconds > 0, "Lock duration must be > 0");
        require(deposits[msg.sender].amount == 0, "Already have an active deposit");

        deposits[msg.sender] = Deposit({
            amount: msg.value,
            unlockTime: block.timestamp + _lockDurationInSeconds
        });

        emit Deposited(msg.sender, msg.value, deposits[msg.sender].unlockTime);
    }

    // ─── Withdraw ──────────────────────────────────────────────
    function withdraw() external {
        Deposit storage d = deposits[msg.sender];

        require(d.amount > 0, "No active deposit found");
        require(block.timestamp >= d.unlockTime, "Funds are still locked");

        uint256 amountToSend = d.amount;

        // Clear deposit before transferring (prevent reentrancy)
        delete deposits[msg.sender];
        emit Withdrawn(msg.sender, amountToSend);

        (bool success, ) = msg.sender.call{value: amountToSend}("");
        require(success, "Withdrawal failed");
    }

    // ─── View Helpers ──────────────────────────────────────────
    function getDeposit() external view returns (uint256 amount, uint256 unlockTime) {
        Deposit storage d = deposits[msg.sender];
        return (d.amount, d.unlockTime);
    }

    function getTimeRemaining() external view returns (uint256 secondsLeft) {
        Deposit storage d = deposits[msg.sender];
        require(d.amount > 0, "No active deposit found");

        if (block.timestamp >= d.unlockTime) {
            return 0;
        }

        return d.unlockTime - block.timestamp;
    }
}
