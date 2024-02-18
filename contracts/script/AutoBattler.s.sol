// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {AutoBattler} from "../src/AutoBattler.sol";
import {UltraVerifier as ArmyVerifier} from "../src/ArmyVerifier.sol";
import {UltraVerifier as BattlerVerifier} from "../src/BattlerVerifier.sol";

contract AutoBattlerScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");
        address account = vm.addr(privateKey);

        console.log("Deployer Account is", account);

        vm.startBroadcast(privateKey);
        ArmyVerifier armyVerifier = new ArmyVerifier();
        BattlerVerifier battlerVerifier = new BattlerVerifier();
        AutoBattler autoBattler = new AutoBattler(address(armyVerifier), address(battlerVerifier));
        vm.stopBroadcast();

        console.log("ArmyVerifier created at address: ", address(armyVerifier));
        console.log("BattlerVerifier created at address: ", address(battlerVerifier));
        console.log("AutoBattler created at address: ", address(autoBattler));
    }
}