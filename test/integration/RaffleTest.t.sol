//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {lottery} from "../../src/lottery.sol";
import {Deploylottery} from "../../script/Deploylottery.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Helperconfig} from "../../script/HelperConfig.s.sol";

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
    address user = makeAddr("user");
    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant INITIAL_VALUE = 10 ether;

    event Raffle_entered(address indexed player);

    function setUp() external {
        Deploylottery deploy = new Deploylottery();
        (raffle, helperconfig) = deploy.run();
        (
            fee,
            interval,
            vrfaddress,
            keyhash,
            subId,
            callgaslimit,
            link
        ) = helperconfig.getConfig();
        vm.deal(user, INITIAL_VALUE);
    }

    modifier entered() {
        vm.startPrank(user);
        raffle.enterraffle{value: SEND_VALUE}();
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
        raffle.enterraffle{value: SEND_VALUE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.PerformUpKeep("");
        vm.expectRevert(lottery.Raffle__NotOpen.selector);
        vm.prank(user);
        raffle.enterraffle{value: SEND_VALUE}();
    }

    function testChekupkeepreturnsfalseifnobalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeep, ) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupkeepreturnsfalseifnottimeinterval() public {
        vm.warp(block.timestamp);
        vm.roll(block.number);
        (bool upkeep, ) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupkeepreturnsFalseifraffleiscalculating() public {
        vm.prank(user);
        raffle.enterraffle{value: fee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.PerformUpKeep("");
        (bool upkeep, ) = raffle.CheckUpKeep("");
        assert(!upkeep);
    }

    function testCheckupreturnstrueifallgood() public entered {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeep, ) = raffle.CheckUpKeep("");
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
            abi.encodeWithSelector(
                lottery.Raffle__NotUpkeep.selector,
                currentbalance,
                currentplayers,
                rafflestate
            )
        );
        raffle.PerformUpKeep("");
    }

    function testfullfillrandomwordscanbecalledafterPerformupkeep()
        public
        entered
    {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
    }
}
