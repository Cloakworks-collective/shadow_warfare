//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAutoBattler.sol";

contract AutoBattler is IAutoBattler {

    uint public constant ARMY_SIZE = 1000;

    /// CONSTRUCTOR ///
    
    /**
     * Construct new instance of AutoBattler manager
     *
     * @param _armyVerifierAddress address - the address of the initial army validity prover
     * @param _battleVerifierAddress address - the address of the attack report prover
     */
    constructor(address _armyVerifierAddress, address _battleVerifierAddress) {
        armyVerifier = IArmyVerifier(_armyVerifierAddress);
        battleVerifier = IBattleVerifier(_battleVerifierAddress);
        gameRecord.attackNonce = 0;
    }

    /// FUNCTIONS ///

    function buildCity(bytes memory _proof, bytes32 defenseArmyHash) external override canBuild {
        // Validate player's army configuration and update defenseArmyHash
        _defendCity(_proof, defenseArmyHash);

        // Set up a default city
        City memory city;
        city.points = 0;
        city.cityStatus = CityStatus.InPeace;
        city.target = address(0);
        city.attacker = address(0);
        city.attackedAt = 0;

        // Add the new city to the game record
        gameRecord.player[msg.sender] = city;
    }

    function deployNewDefenseArmy(bytes memory _proof, bytes32 defenseArmyHash) external override isPlayer isDefeated {
        // Validate player's army configuration and update defenseArmyHash
        _defendCity(_proof, defenseArmyHash);

        // Update city status
        gameRecord.player[msg.sender].cityStatus = CityStatus.InPeace;
    }

    function attack(address _target, Army memory _attackerArmy)
        external
        override
        isPlayer
        canAttack
        isAttackable(_target)
    {   
        // validate the composition of the attacking army
        uint totalArmyCount = _attackerArmy.tanks + _attackerArmy.artillery + _attackerArmy.infantry;
        require(totalArmyCount == ARMY_SIZE, "Army size exceeds limit!");

        // Fetch the target's city
        City storage defenderCity = gameRecord.player[_target];

        // Update the city state of the target player
        defenderCity.cityStatus = CityStatus.UnderAttack;
        defenderCity.attacker = msg.sender;
        defenderCity.attackedAt = block.timestamp;
        defenderCity.attackingArmy = _attackerArmy;

        // Update the city state of the attacking player
        City storage attackerCity = gameRecord.player[msg.sender];
        attackerCity.target = _target;

        // Increment the attack nonce
        gameRecord.attackNonce++;

        // Emit battle/clash event
        emit Clash(msg.sender, _target, gameRecord.attackNonce);
    }

    function reportAttack(uint battle_result, bytes calldata _proof) external override isPlayer isUnderAttack {
        // Assert battle result is zero or one 
        require(battle_result == 0 || battle_result == 1, "Battle result must be zero or one");
        
        // Fetch the defender's city(the caller)
        City storage defenderCity = gameRecord.player[msg.sender];

        // Fetch the attacker's address and then city
        address attacker_address = defenderCity.attacker;
        City storage attackerCity = gameRecord.player[attacker_address];
        
        // Fetch the attacker's city Army
        Army memory attacker_army = defenderCity.attackingArmy;
        
        // Check proof uses the caller's army commitment(defenseArmyHash)
        require(validateArmyCommitment(_proof, defenderCity.defenseArmyHash), "Non compliant army commitment!");

        // Set up the public inputs for the battle verifier 
        bytes32[] memory publicInputs = new bytes32[](5);
        publicInputs[0] = defenderCity.defenseArmyHash;
        publicInputs[1] = bytes32(attacker_army.infantry);
        publicInputs[2] = bytes32(attacker_army.artillery);
        publicInputs[3] = bytes32(attacker_army.tanks);
        publicInputs[4] = bytes32(battle_result);
        
        // Check if the battle proof is valid
        if (!battleVerifier.verify(_proof, publicInputs)) {
            revert("Invalid attack report proof");
        } 

        if (battle_result == 0) {
            // Update the city state of the defender player(the caller)
            defenderCity.cityStatus = CityStatus.Destroyed;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);

            // Update the city state of the attacking player
            attackerCity.target = address(0);
            attackerCity.points += 1;

            // Emit event that the attacking player has destroyed the caller
            emit Destroyed(msg.sender, gameRecord.attackNonce);
        } else {
            // Update the city state of the defender player(the caller)
            defenderCity.cityStatus = CityStatus.Defended;
            defenderCity.attacker = address(0);
            defenderCity.attackedAt = 0;
            defenderCity.attackingArmy = Army(0, 0, 0);
            defenderCity.points += 1;

            // Update the city state of the attacking player
            attackerCity.target = address(0);

            // Emit event that the defender(caller) has successfully defender his city
            emit Defended(msg.sender, gameRecord.attackNonce);
        }
    }

    /**
     * The defender calls this method in case he/she want to surrender to the attacker.
     */
    function surrender() external override isPlayer isUnderAttack {
        // Fetch the target's city
        City storage defenderCity = gameRecord.player[msg.sender];

        // Update the city state of the current player
        defenderCity.cityStatus = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // Update the city state of the attacking player
        City storage attackerCity = gameRecord.player[defenderCity.attacker];
        attackerCity.target = address(0);
        //TODO update player points according to battle points
        attackerCity.points += 1;

        // Emit surrender event
        emit Surrendered(msg.sender, gameRecord.attackNonce);
    }

    /**
     * If this player's target does not report battle result within 24 hours then the message sender
     * calls this method to claim his/her battle points.
     */
    function lootCity() external override isPlayer {
        // Fetch the target's player address
        City memory attackerCity = gameRecord.player[msg.sender];
        address target = attackerCity.target;

        // Fetch the target's city data
        City storage defenderCity = gameRecord.player[target];

        // Check if the target has not reported the battle result within one day
        if (defenderCity.attackedAt + 1 days > block.timestamp) {
            revert("Surrender period has not passed");
        }

        // Update the city state of the target's city(defender)
        defenderCity.cityStatus = CityStatus.Surrendered;
        defenderCity.attacker = address(0);
        defenderCity.attackedAt = 0;
        defenderCity.attackingArmy = Army(0, 0, 0);

        // Update the city state of the attacking player(the caller)
        attackerCity.target = address(0);
        attackerCity.points += 1;

        // Emit Looted event
        emit Looted(msg.sender, gameRecord.attackNonce);
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
            bytes32 _defenseArmyHash,
            CityStatus _cityStatus,
            uint256 _points,
            address _attacker,
            uint256 _attackedAt,
            address _target,
            Army memory _attackingArmy
        )
    {
        _defenseArmyHash = gameRecord.player[_player].defenseArmyHash;
        _cityStatus = gameRecord.player[_player].cityStatus;
        _points = gameRecord.player[_player].points;
        _attacker = gameRecord.player[_player].attacker;
        _attackedAt = gameRecord.player[_player].attackedAt;
        _target = gameRecord.player[_player].target;
        _attackingArmy = gameRecord.player[_player].attackingArmy;
    }

    /// INTERNAL ///

    /**
     * Defends the city by commiting a defense army.
     * @dev modifier canBuild
     *
     * @param _proof bytes memory - zk proof of valid army
     */
    function _defendCity(bytes memory _proof, bytes32 defenseArmyHash) internal {
        // Verify integrity of defense army configuration
        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = defenseArmyHash;
        require(armyVerifier.verify(_proof, publicInputs), "Invalid Army Configuration!");

        // Extract army commitment from public inputs to enforce battle proof inputs against
        bytes32 armyCommitment;
        assembly {
            armyCommitment := mload(add(_proof, 32))
        }

        // Update the city defenseArmyHash
        gameRecord.player[msg.sender].defenseArmyHash = armyCommitment;
    }

    /**
     * Checks that the army commitment in a battle proof is the same as a given commitment(defenseArmyHash)
     * @dev army commitment is stored in the first 32 bytes of a proof string
     *
     * @param _proof bytes - the proof string to extract public inputs from
     * @param _armyCommitment bytes32 - the commitment to compare against extracted value
     * @return ok bool - true if commitments match
     */
    function validateArmyCommitment(bytes memory _proof, bytes32 _armyCommitment) internal pure returns (bool ok) {
        assembly {
            let commitment := mload(add(_proof, 32))
            ok := eq(commitment, _armyCommitment)
        }
    }
}
