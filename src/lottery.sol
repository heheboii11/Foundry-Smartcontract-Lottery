// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A sample Raffle Contract
 * @author Karthik
 * @notice This contarct is for creating a sample raffle contract better than our fundme contract.
 * @dev Implements Chainlink VRFv2
 */
contract lottery is VRFConsumerBaseV2 {
    /**
     * errors
     */
    error Raffle__Notennougheth();
    error Raffle__NotTransferred();
    error Raffle__NotOpen();
    error Raffle__NotUpkeep(uint256 balance, uint256 length, RaffleState state);
    /**
     * Type declaration
     */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * state variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entrancefee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyhash;
    uint32 private immutable i_callbackgas;
    uint64 private immutable i_subscriptionId;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_lastWinner;
    RaffleState private s_rafflestate;
    bool enter = true;

    /**
     * event
     */
    event Raffle_entered(address indexed player);
    event Raffle_PickedWinner(address indexed winner);
    event RequestedraffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entrancefee,
        uint256 interval,
        address vrfCordinator,
        bytes32 keyhash,
        uint64 subscriptionId,
        uint32 callbackgaslimit
    ) VRFConsumerBaseV2(vrfCordinator) {
        i_entrancefee = entrancefee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCordinator);
        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackgas = callbackgaslimit;
        s_lastTimestamp = block.timestamp;
        s_rafflestate = RaffleState.OPEN;
    }

    function enterraffle() external payable feeamount(i_entrancefee) {
        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        if (msg.value != i_entrancefee) {
            revert();
        }
        s_players.push(payable(msg.sender));
        emit Raffle_entered(msg.sender);
    }

    modifier feeamount(uint256 fee) {
        require(msg.value == fee, "not exact eth");
        _;
    }

    function CheckUpKeep(bytes memory /* checkdata */ )
        public
        view
        returns (bool Upkeep, bytes memory /* performdata */ )
    {
        bool Timehaspasses = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool Enoughbalance = address(this).balance > 0;
        bool Enoughpeople = s_players.length > 0;
        bool Raffleisopen = RaffleState.OPEN == s_rafflestate;
        Upkeep = (Timehaspasses && Enoughbalance && Enoughpeople && Raffleisopen);
        return (Upkeep, "0x0");
    }

    function PerformUpKeep(bytes calldata /* performdata */ ) external {
        (bool Upkeep,) = CheckUpKeep("");
        if (!Upkeep) {
            revert Raffle__NotUpkeep(address(this).balance, s_players.length, RaffleState(s_rafflestate));
        }

        s_rafflestate = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyhash, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackgas, NUM_WORDS
        );
        emit RequestedraffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /* requestID */ uint256[] memory randomWords) internal override {
        uint256 IndexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[IndexOfWinner];
        s_lastWinner = winner;
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit Raffle_PickedWinner(winner);
        (bool sent,) = winner.call{value: address(this).balance}("");
        //require(sent, Raffle__NotTransferred);
        if (!sent) {
            revert Raffle__NotTransferred();
        }
    }

    /**
     * Getter functions
     */
    function get_entrancefee() external view returns (uint256) {
        return i_entrancefee;
    }

    function get_StateoftheRaffle() external view returns (RaffleState) {
        return s_rafflestate;
    }

    function get_players(uint256 Indexofplayer) external view returns (address) {
        return s_players[Indexofplayer];
    }

    function get_recentWinner() external view returns (address) {
        return s_lastWinner;
    }

    function get_playerslength() external view returns (uint256) {
        return s_players.length;
    }

    function get_lasttimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
