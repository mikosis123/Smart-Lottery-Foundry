// SPDX-License-Identifier : MIT
pragma solidity ^0.8.19;

/**
 * @title Raffle contract
 * @author miko_sis
 */
contract Raffle {
    error Raffle__NotEnoughEntranceFee();

    uint256 private immutable i_entranceFee;
    address payable[] public s_players;

    constructor(uint256 entranceFee) { 
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require (msg.value >= i_entranceFee,"not enough entrance");
        // require(msg.value >= i_entranceFee,NotEnoughEntranceFee());
        if (msg.value < i_entranceFee) {
            revert NotEnoughEntranceFee();
        }
        s_players.push(payable(msg.sender));
    }

    function pickWinner() public {}

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}

