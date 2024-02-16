// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

uint256  constant MAX_TROOPS = 10_000;

uint256 constant INFANTRY_POP_COST = 1;
uint256 constant TANK_POP_COST = 3;
uint256 constant ARTILLERY_POP_COST = 5;

uint256 constant INFANTRY_ADVANTAGE_ARTILLERY = 2;
uint256 constant TANK_ADVANTAGE_INFANTRY = 2;
uint256 constant ARTILLERY_ADVANTAGE_TANK = 2;