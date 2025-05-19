// SPDX-License-Identifier : MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title Raffle contract
 * @author miko_sis
 */

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEntranceFee();
    error Transfer_Failed();
    error Raffle__NotOpen(uint256 balance, uint256 players, uint256 state);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;
    RaffleState private s_RaffleState;
    uint256 private immutable i_entranceFee;
    uint256 public immutable i_interval;
    bytes32 public immutable i_keyHash;
    uint256 public immutable i_subscriptionId;
    uint32 public immutable i_callbackGasLimit;
    uint256 public immutable s_startingTime;
    uint256 public s_LastTimeStamp;
    address payable[] public s_players;

    event RaffleEnterd(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_startingTime = block.timestamp;
        i_keyHash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_RaffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        // require (msg.value >= i_entranceFee,"not enough entrance");
        // require(msg.value >= i_entranceFee,NotEnoughEntranceFee());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEntranceFee();
        }
        if (s_RaffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen(address(this).balance, s_players.length, uint256(s_RaffleState));
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnterd(msg.sender);
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = (RaffleState.OPEN == s_RaffleState);
        bool timePassed = ((block.timestamp - s_LastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    // get the random number
    //use the random number to pick the winner
    function pickWinner() public {
        // if ((block.timestamp - s_startingTime) < i_interval) {
        //     revert();
        // }
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__NotOpen(address(this).balance, s_players.length, uint256(s_RaffleState));
        }
        s_RaffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address winner = s_players[winnerIndex];
        s_RaffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_LastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);
        (bool sucesss,) = winner.call{value: address(this).balance}("");
        if (!sucesss) {
            revert Transfer_Failed();
        }
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
