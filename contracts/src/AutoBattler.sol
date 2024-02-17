//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAutoBattler.sol";

contract AutoBattler is IAutoBattler {
    /// CONSTRUCTOR ///

    /**
     * Construct new instance of Battleship manager
     *
     * @param _armyVerifierAddress address - the address of the initial army validity prover
     * @param _battleVerifierAddress address - the address of the attack report prover
     */
    constructor(
        address _armyVerifierAddress,
        address _battleVerifierAddress
    ) {
        armyVerifier = IArmyVerifier(_armyVerifierAddress);
        battleVerifier = IAttackVerifier(_battleVerifierAddress);
        gameRecord.attackNonce = 1;
        gameRecord.cityNonce = 1;
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
        city.id = gameRecord.cityNonce;
        city.name = _name;
        city.faction = _faction;
        city.points = 0;
        city.cityStatus = CityStatus.InPeace;
        city.target = address(0);
        city.attacker = address(0);
        city.attackedAt = 0;
        
    
        // add the city to the game record
        gameRecord.player[msg.sender] = city;

        // increment the city nonce
        gameRecord.cityNonce++;
    }

    function defendCity(bytes calldata _proof) public  canBuild() override {
        // check if the proof is valid
        if(!armyVerifier.verify(_proof)) {
            revert("Invalid army proof");
        }

        // update the city army
        gameRecord.player[msg.sender].defenseArmyHash = keccak256(_proof);
        
    }

    function attack(
        address _target,
        Army memory _attackerArmy
    ) isPlayer() canAttack() isAttackable(_target) external override {

        // get the defender's city
        City storage defenderCity = gameRecord.player[_target];

        // update the city status
        defenderCity.cityStatus = CityStatus.UnderAttack;
        defenderCity.attacker = msg.sender;
        defenderCity.attackedAt = block.timestamp;
        defenderCity.attackingArmy = _attackerArmy;

        // update the attacker's city
        City storage attackerCity = gameRecord.player[msg.sender];
        attackerCity.target = _target;

        gameRecord.attackNonce++;
        emit Clash(msg.sender, _target, gameRecord.attackNonce);
        
    }

    function reportAttack(
        bool attacker_wins,
        bytes calldata _proof
    ) isPlayer() isUnderAttack() external override {
        // get the defender's city
        City storage defenderCity = gameRecord.player[msg.sender];

        // check if the proof is valid
        if(!battleVerifier.verify(_proof)){
            revert("Invalid attack report proof");
        }

        if (attacker_wins) {
            // update the city status
            defenderCity.cityStatus = CityStatus.Destroyed;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);

            // update the attacker's city
            City storage attackerCity = gameRecord.player[msg.sender];
            attackerCity.target = address(0);
            attackerCity.points += 1;


            emit Destroyed(msg.sender, gameRecord.attackNonce);
        } else {

            // update the city status
            defenderCity.cityStatus = CityStatus.Defended;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);
            defenderCity.points += 1;

            // update the attacker's city
            City storage attackerCity = gameRecord.player[msg.sender];
            attackerCity.target = address(0);

            // update the city status
            emit Defended(msg.sender, gameRecord.attackNonce);
        }

    }


    // defender is calling it
    function surrender() isPlayer() isUnderAttack() external override {
        // get the defender's city
        City storage defenderCity = gameRecord.player[msg.sender];

        // update the city status
        defenderCity.cityStatus = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // update the attacker's city
        City storage attackerCity = gameRecord.player[defenderCity.attacker];
        attackerCity.target = address(0);
        attackerCity.points += 1;

        emit Surrendered(msg.sender, gameRecord.attackNonce);
    }

    // attacker is calling it
    function lootCity() isPlayer() external override {

        // get defender 
        City memory attackerCity = gameRecord.player[msg.sender];
        address target = attackerCity.target;

        // get the defender's city
        City storage defenderCity = gameRecord.player[target];

        // check if target has surrenedered or not 
        if (defenderCity.attackedAt + 1 days > block.timestamp) {
            revert("Surrender period has not passed");
        }

        // update the city status
        defenderCity.cityStatus = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // update the attacker's city
        attackerCity.target = address(0);
        attackerCity.points += 1;

        emit Surrendered(target, gameRecord.attackNonce);
    }

    function findAttackableCity() external view override returns (address) {
        require(gameRecord.attackable.length > 0, "Cannot find any attackable city!");
        
        // Generate a pseudo-random number using block timestamp and contract address
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, address(this))));
        uint256 randomIndex = randomNumber % gameRecord.attackable.length;
        
        return gameRecord.attackable[randomIndex];
    }


    /// VIEWS ///

    function playerState(address _player)
        external
        view
        override
        returns (
            uint256 _id,
            bytes32 _defenseArmyHash,
            bytes32 _name,
            CityStatus _cityStatus,
            uint256 _points,
            address _attacker,
            uint256 _attackedAt,
            address _target,
            Army memory _attackingArmy
        )
    {
        _id = gameRecord.player[_player].id;
        _defenseArmyHash = gameRecord.player[_player].defenseArmyHash ;
        _name = gameRecord.player[_player].name;
        _cityStatus = gameRecord.player[_player].cityStatus;
        _points = gameRecord.player[_player].points;
        _attacker = gameRecord.player[_player].attacker;
        _attackedAt = gameRecord.player[_player].attackedAt;
        _target = gameRecord.player[_player].target;
        _attackingArmy = gameRecord.player[_player].attackingArmy;
    }

    /// INTERNAL /// 
}