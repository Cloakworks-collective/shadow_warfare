// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

    enum ArmyType {
        Tank,
        Artillery,
        Infantry
    }
    
    enum CityType {
        Tokyo,
        Miami,
        Singapore
    }

    struct Army {
        uint256 infantry;
        uint256 tanks;
        uint256 artillery;
    }

    struct Player {
        uint256 id;
        uint256 wins;
        address owner;
    }

    struct City {
        uint256 id;
        Player ruler;
        bool defenseVerified;
        bool defenseRevealed;
        uint256 citytype;
        bytes32 defenseHash;
    }

   struct Battle {
        uint256 defenderCity;
        Army attackerArmy;
        address defender;
        bytes32 defense;
        bytes32 attack;
    }

    

    

