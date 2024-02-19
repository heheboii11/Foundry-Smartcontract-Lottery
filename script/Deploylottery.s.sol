// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {lottery} from "../src/lottery.sol";
import {Helperconfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription, Fundsubscription, Addconsumer} from "../script/interaction.s.sol";

contract Deploylottery is Script {
    function run() external returns (lottery, Helperconfig) {
        Helperconfig helperconfig = new Helperconfig();
        (
            uint256 fee,
            uint256 interval,
            address vrfaddress,
            bytes32 keyhash,
            uint64 subId,
            uint32 callgaslimit,
            address link,
            uint256 deployerKey
        ) = helperconfig.getConfig();
        if (subId == 0) {
            CreateSubscription createsub = new CreateSubscription();
            subId = createsub.createsubscription(vrfaddress, deployerKey);
            Fundsubscription fundsub = new Fundsubscription();
            fundsub.fundsubscription(vrfaddress, subId, link, deployerKey);
        }
        vm.startBroadcast(deployerKey);

        lottery raffle = new lottery(fee, interval, vrfaddress, keyhash, subId, callgaslimit);
        vm.stopBroadcast();
        Addconsumer addconsumer = new Addconsumer();
        addconsumer.addconsumer(address(raffle), vrfaddress, subId, deployerKey);
        return (raffle, helperconfig);
    }
}
