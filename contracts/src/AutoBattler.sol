//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAutoBattler.sol";

contract AutoBattler is IAutoBattler {

    /// CONSTRUCTOR ///

    /**
     * Construct new instance of Battleship manager
     *
     * @param _av address - the address of the initial army validity prover
     * @param _sv address - the address of the attack report prover
     */
    constructor(
        address _av,
        address _sv
    ) {
        av = IArmyVerifier(_av);
        sv = IAttackVerifier(_sv);
        GameRecord.attackNonce = 1;
        GameRecord.cityNonce = 1;
    }

    /// FUNCTIONS ///

    function buildCity(
        bytes32 _name,
        Faction _faction,
        bytes  calldata _proof
    ) canBuild() external override {

        defendCity(_proof);

        // make a default city 
        City memory city; 
        city.id = GameRecord.cityNonce;
        city.name = _name;
        city.faction = _faction;
        city.points = 0;
        city.status = CityStatus.InPeace;
        city.target = address(0);
        city.attacker = address(0);
        city.attackedAt = 0;
        
    
        // add the city to the game record
        GameRecord.player[msg.sender] = city;

        // increment the city nonce
        GameRecord.cityNonce++;
    }

    function defendCity(bytes calldata _proof) public  canBuild() override {
        // check if the proof is valid
        if(!av.verify(_proof)){
            revert("Invalid army proof");
        }

        // update the city army
        GameRecord.player[msg.sender].cityArmyHash = keccak256(_proof);
        
    }

    function attack(
        address _defender,
        ArmyType _attackerArmyUnit,
        uint256 _attackerArmyCount,
    ) isPlayer()  canAttack() isAttackable(_defender) external override {

        // attacker's army
        Army memory attackerArmy;
        attackerArmy[_attackerArmyUnit] = _attackerArmyCount;

        // get the defender's city
        City storage defenderCity = GameRecord.player[_defender];

        // update the city status
        defenderCity.status = CityStatus.UnderAttack;
        defenderCity.attacker = msg.sender;
        defenderCity.attackedAt = block.timestamp;
        defenderCity.attackingArmy = attackerArmy;

        // update the attacker's city
        City storage attackerCity = GameRecord.player[msg.sender];
        attackerCity.target = _defender;

        GameRecord.attackNonce++;
        emit Clash(msg.sender, _defender, GameRecord.attackNonce);
        
    }

    function reportAttack(
        address _defender,
        bool attacker_wins,
        bytes calldata _proof
    ) isPlayer() isUnderAttack() external override {
        // get the defender's city
        City storage defenderCity = GameRecord.player[_defender];

        // check if the proof is valid
        if(!sv.verify(_proof)){
            revert("Invalid attack report proof");
        }

        if (attacker_wins) {
            // update the city status
            defenderCity.status = CityStatus.Destroyed;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);

            // update the attacker's city
            City storage attackerCity = GameRecord.player[msg.sender];
            attackerCity.defender = address(0);
            attackerCity.points += 1;

            emit Destroyed(_defender, GameRecord.attackNonce);
        } else {

            // update the city status
            defenderCity.status = CityStatus.Defended;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);
            defenderCity.points += 1;

            // update the attacker's city
            City storage attackerCity = GameRecord.player[msg.sender];
            attackerCity.defender = address(0);

            // update the city status
            emit Defended(msg.sender, GameRecord.attackNonce);
        }

    }


    // defender is calling it
    function surrender() isPlayer() isUnderAttack() external override {
        // get the defender's city
        City storage defenderCity = GameRecord.player[msg.sender];

        // update the city status
        defenderCity.status = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // update the attacker's city
        City storage attackerCity = GameRecord.player[defenderCity.attacker];
        attackerCity.defender = address(0);
        attackerCity.points += 1;

        emit Surrendered(_attacker, GameRecord.attackNonce);
    }

    // attacker is calling it
    function claimSurrender() isPlayer() isUnderAttack() external override {

        // get defender 
        attackerCity = GameRecord.player[msg.sender];
        target = attackerCity.target;

        // get the defender's city
        City storage defenderCity = GameRecord.player[target];

        if (defenderCity.attackedAt + 1 days > block.timestamp) {
            revert("Surrender period has not passed");
        }

        // update the city status
        defenderCity.status = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // update the attacker's city
        attackerCity.target = address(0);
        attackerCity.points += 1;

        emit Surrendered(target, GameRecord.attackNonce);
    }

}