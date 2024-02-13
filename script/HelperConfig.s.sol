// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/integration/mocks/Link.sol";

contract Helperconfig is Script {
    struct NetworkConfig {
        uint256 fee;
        uint256 interval;
        address vrfaddress;
        bytes32 keyhash;
        uint64 subId;
        uint32 callgaslimit;
        address link;
    }
    NetworkConfig public getConfig;
    uint96 Basefee = 0.25 ether;
    uint96 gaspricelink = 1e9;

    constructor() {
        if (block.chainid == 11155111) {
            getConfig = getSepoliaConfig();
        } else {
            getConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                fee: 0.01 ether,
                interval: 30,
                vrfaddress: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                keyhash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subId: 8781,
                callgaslimit: 2500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (getConfig.vrfaddress != address(0)) {
            return getConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfcoordinatormock = new VRFCoordinatorV2Mock(
            Basefee,
            gaspricelink
        );
        LinkToken link = new LinkToken();

        vm.stopBroadcast();
        return
            NetworkConfig({
                fee: 0.01 ether,
                interval: 30,
                vrfaddress: address(vrfcoordinatormock),
                keyhash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subId: 0,
                callgaslimit: 500000,
                link: address(link)
            });
    }
}
