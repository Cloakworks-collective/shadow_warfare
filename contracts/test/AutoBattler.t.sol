// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NoirProver} from "foundry-noir/Noir.sol";

import {AutoBattler} from "../src/AutoBattler.sol";
import {UltraVerifier as ArmyVerifier} from "../src/ArmyVerifier.sol";



contract AutoBattlerTest is Test {
    NoirProver public noirProver;
    ArmyVerifier public armyVerifier;

    function setUp() public {
        armyVerifier = new ArmyVerifier();
        noirProver = new NoirProver()
            .with_nargo_project_path("../circuits/army");
    }

    function testGenerateAndVerifyProof() public {
        noirProver
            .with_input(NoirProver.CircuitInput("army", [200, 300, 500]))
            .with_public_input(NoirProver.CircuitInput("army_hash", 0x02b55d34358004a8e51d4403e936cfbc6f1c3fac38ffd40a30015389575f23d8));

        bytes memory proof = noirProver.generate_proof();
        armyVerifier.verifyProof(proof, [0x02b55d34358004a8e51d4403e936cfbc6f1c3fac38ffd40a30015389575f23d8]);
    }

}
