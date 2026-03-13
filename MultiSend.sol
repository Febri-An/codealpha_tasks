// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

contract MultiSend {

    function multiSend(address[] calldata recipients) external payable {
        require(recipients.length > 0, "No recipients provided");
        require(msg.value > 0, "Must send some Ether");

        uint256 amountPerRecipient = msg.value / recipients.length; // recipient will be got the same amount
        require(amountPerRecipient > 0, "Amount too small to split");

        // Denial of Service (but it's okay for now)
        // Reentrancy Attack (medium)
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid address");
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
        }

        // Refund any leftover dust (from division remainder)
        uint256 leftover = msg.value - (amountPerRecipient * recipients.length);
        if (leftover > 0) {
            (bool refunded, ) = msg.sender.call{value: leftover}("");
            require(refunded, "Refund failed");
        }
    }
}
