//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {lottery} from "../../src/lottery.sol";
import {Deploylottery} from "../../script/Deploylottery.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Helperconfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract Testlottery is Test {
    lottery raffle;
    Helperconfig helperconfig;
    uint256 fee;
    uint256 interval;
    address vrfaddress;
    bytes32 keyhash;
    uint64 subId;
    uint32 callgaslimit;
    address link;
    uint256 deployerKey;
    address user = makeAddr("user");
    // uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant INITIAL_VALUE = 10 ether;

    event Raffle_entered(address indexed player);
    event Raffle_PickedWinner(address indexed winner);

    function setUp() external {
        Deploylottery deploy = new Deploylottery();
        (raffle, helperconfig) = deploy.run();
        (fee, interval, vrfaddress, keyhash, subId, callgaslimit, link,) = helperconfig.getConfig();
        vm.deal(user, INITIAL_VALUE);
    }

    modifier entered() {
        vm.startPrank(user);
        raffle.enterraffle{value: fee}();
        vm.stopPrank();
        _;
    }

    function testcontarctstateintial() public view {
        assert(raffle.get_StateoftheRaffle() == lottery.RaffleState.OPEN);
    }

    function testenterraffle() public entered {
        // vm.prank(user);
        // raffle.enterraffle{value: fee}();
        // console.log(address(user).balance);
        // console.log(raffle.get_players(0).balance);
        assert(raffle.get_players(0) == address(user));
    }

    function testEnoughethnotsent() public {
        vm.prank(user);
        vm.expectRevert();
        raffle.enterraffle{value: 1 ether}();
    }

    function testEventemittedonentering() public {
        vm.prank(user);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle_entered(user);
        raffle.enterraffle{value: fee}();
    }

    function testerrorwhencalculating() public {
        vm.prank(user);
        raffle.enterraffle{value: fee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.PerformUpKeep("");
        vm.expectRevert(lottery.Raffle__NotOpen.selector);
        vm.prank(user);
        raffle.enterraffle{value: fee}();
    }

    function testChekupkeepreturnsfalseifnobalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeep,) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupkeepreturnsfalseifnottimeinterval() public {
        vm.warp(block.timestamp);
        vm.roll(block.number);
        (bool upkeep,) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupkeepreturnsFalseifraffleiscalculating() public {
        vm.prank(user);
        raffle.enterraffle{value: fee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.PerformUpKeep("");
        (bool upkeep,) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupreturnstrueifallgood() public entered {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeep,) = raffle.CheckUpKeep("");
        assert(upkeep);
    }

    function testPerformupkeepifupkeepistrue() public entered {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.PerformUpKeep("");
    }

    function testPerformupkeepifupkeepisfalse() public {
        uint256 currentplayers = 0;
        uint256 currentbalance = 0;
        uint256 rafflestate = 0;
        vm.expectRevert(
            abi.encodeWithSelector(lottery.Raffle__NotUpkeep.selector, currentbalance, currentplayers, rafflestate)
        );
        raffle.PerformUpKeep("");
    }

    function testfullfillrandomwordscanbecalledafterPerformupkeep(uint256 requestid) public enteredandtimepassed {
        if (block.chainid == 11155111) {
            return;
        }
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfaddress).fulfillRandomWords(requestid, address(raffle));
    }

    modifier enteredandtimepassed() {
        vm.startPrank(user);
        raffle.enterraffle{value: fee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepupdatesRafflestateandemitsrequestid() public enteredandtimepassed {
        vm.recordLogs();
        raffle.PerformUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        lottery.RaffleState state = raffle.get_StateoftheRaffle();
        assert(uint256(state) == 1);
        assert(uint256(requestId) > 0);
    }

    function testfinalraffleworking() public entered {
        if (block.chainid == 11155111) {
            return;
        }
        uint256 noofaddress = 5;
        uint256 index = 1;
        uint256 time = block.timestamp;
        uint256 prize = fee * (noofaddress + 1);
        for (uint256 i = index; i < index + noofaddress; i++) {
            address player = address(uint160(i));
            hoax(player, INITIAL_VALUE);
            raffle.enterraffle{value: fee}();
        }
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        raffle.PerformUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // vm.expectEmit(true, false, false, false, address(raffle));
        // emit Raffle_PickedWinner(raffle.get_recentWinner());
        VRFCoordinatorV2Mock(vrfaddress).fulfillRandomWords(uint256(requestId), address(raffle));
        console.log("here is the balance of winner", raffle.get_recentWinner().balance);
        console.log(INITIAL_VALUE + prize - fee);
        assert(raffle.get_recentWinner() != address(0));
        assert(uint256(raffle.get_StateoftheRaffle()) == 0);
        assert(raffle.get_playerslength() == 0);
        assert(raffle.get_lasttimestamp() > time);
        assert(raffle.get_recentWinner().balance == INITIAL_VALUE + prize - fee);
    }
}
