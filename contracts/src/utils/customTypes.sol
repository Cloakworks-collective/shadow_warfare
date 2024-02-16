// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


   struct Battle {
        uint256 cityId;
        address attacker;
        address defender;
        bytes32 defense;
        bytes32 attack;
    }

    struct City {
        address owner;
        bool defenseVerified;
        uint256 infantry;
    }

    struct Army {
        uint256 infantry;
        uint256 tanks;
        uint256 artillery;
    }


    struct CommitDefenseParams {
        bytes proof;
        uint256 cityId;
    }

    struct CommitAttackParams {
        uint256 cityId;
        bytes32 attack;
    }

    struct VerifyDefenseParams {
        uint256 cityId;
        bytes proof;
    }

