//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {Helperconfig} from "../script/HelperConfig.s.sol";
import {LinkToken} from "../test/integration/mocks/Link.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createsubscription(address vrfaddress) public returns (uint64) {
        console.log("creating your subscription on chain:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfaddress).createSubscription();
        vm.stopBroadcast();
        console.log("here is your subId:", subId);
        return subId;
    }

    function createsubscriptionusingconfig() public returns (uint64) {
        Helperconfig helperconfig = new Helperconfig();
        (, , address vrfaddress, , , , ) = helperconfig.getConfig();

        return createsubscription(vrfaddress);
    }

    function run() public returns (uint64) {
        return createsubscriptionusingconfig();
    }
}

contract Fundsubscription is Script {
    uint96 constant FUNDAMOUNT = 0.1 ether;

    function fundsubusingConfig() public {
        Helperconfig helperconfig = new Helperconfig();
        (, , address vrfaddress, , uint64 subId, , address link) = helperconfig
            .getConfig();
        fundsubscription(vrfaddress, subId, link);
    }

    function fundsubscription(
        address vrfaddress,
        uint64 subId,
        address link
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfaddress).fundSubscription(
                subId,
                FUNDAMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfaddress,
                FUNDAMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundsubusingConfig();
    }
}

contract Addconsumer is Script {
    function addconsumer(
        address raffle,
        address vrfaddress,
        uint64 subid
    ) public {
        //if (block.chainid == 31337) {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfaddress).addConsumer(subid, raffle);
        vm.stopBroadcast();
        // } else {
        //     vm.startBroadcast();
        //     VRFCoordinatorV2Interface(vrfaddress).addConsumer(subid, raffle);
        //     vm.stopBroadcast();
        // }
    }

    function addconsumerusingconfig(address raffle) public {
        Helperconfig helperconfig = new Helperconfig();
        (, , address vrfaddress, , uint64 subId, , ) = helperconfig.getConfig();
        addconsumer(raffle, vrfaddress, subId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "lottery",
            block.chainid
        );
        addconsumerusingconfig(raffle);
    }
}
