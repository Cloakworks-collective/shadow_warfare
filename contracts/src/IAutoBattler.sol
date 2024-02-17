//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IVerifier.sol";

/**
 * Abstraction for Zero-Knowledge AutoBattler Game
 */
abstract contract IAutoBattler {
    /// EVENTS ///

    event Joined(uint256 _nonce, address _by);
    event Clash(address _attacker, address _defender, uint256 _clash);
    event Defended(address _winner, uint256 _nonce);
    event Destroyed(address _defender, uint256 _nonce);
    event Surrendered(address _loser, uint256 _nonce);
    event Looted(address _attacker, uint256 _nonce);

    /// ENUMS ///

    enum CityStatus {
        NonExistant,
        InPeace,
        UnderAttack,
        Destroyed,
        Defended,
        Surrendered
    }

    /// STRUCTS ///

    struct Army {
        uint256 tank;
        uint256 artillery;
        uint256 infantry;
    }

    struct City {
        uint256 id;
        bytes32 defenseArmyHash;
        bytes32 name;
        CityStatus cityStatus;
        uint256 points;
        address attacker;
        uint256 attackedAt;
        address target;
        Army attackingArmy;
    }

    struct GameRecord {
        uint256 attackNonce; // clash #
        uint256 cityNonce; // city #
        mapping(address => City) player; // map player address to City Data
        address[] attackable; // record of attackable cities infered by player address
    }

    /// VARIABLES ///

    GameRecord public gameRecord; // game record
    IArmyVerifier public armyVerifier; // verifier for proving valid army rule compliance
    IAttackVerifier public battleVerifier; // verifier for proving attack report honesty

    /// MODIFIERS ///

    /**
     * Determine whether message sender has registered of a fortress
     */
    modifier isPlayer() {
        require(gameRecord.player[msg.sender].defenseArmyHash != bytes32(0), "Please register a city first!");
        _;
    }

    /**
     * Determine whether a player is allowed to build a defending city
     */
    modifier canBuild() {
        require(
            gameRecord.player[msg.sender].cityStatus == CityStatus.NonExistant, "You already have a defending city!"
        );
        _;
    }

    /**
     * Ensure a player is defeated.
     */
    modifier isDefeated() {
        require(
            gameRecord.player[msg.sender].cityStatus == CityStatus.Destroyed
                || gameRecord.player[msg.sender].cityStatus == CityStatus.Surrendered,
            "Your army is not defeated!"
        );
        _;
    }

    /**
     * Ensure a message sender is not currently attacking another player
     * Default: null bytes instead of target's army hash
     */
    modifier canAttack() {
        require(
            gameRecord.player[msg.sender].cityStatus == CityStatus.InPeace,
            "You city should be in peace for you to attack"
        );
        require(
            gameRecord.player[msg.sender].target == address(0), "Your opponent did not report the clash result yet!"
        );
        _;
    }

    /**
     * Ensure a message sender is under attack
     */
    modifier isUnderAttack() {
        require(gameRecord.player[msg.sender].cityStatus == CityStatus.UnderAttack, "You city is not under attack!");
        _;
    }

    /**
     * Ensure that a target city is attackable
     */
    modifier isAttackable(address _target) {
        // Check if the address is in the attackable mapping
        bool attackable = false;
        for (uint256 i = 0; i < gameRecord.attackable.length; i++) {
            if (gameRecord.attackable[i] == _target) {
                attackable = true;
            }
        }
        require(attackable == true, "Your target city is not attackable");
        _;
    }

    /**
     * Register a player by Building a City with default parameters.
     * Calls defendCity internally
     * @dev modifier canBuild
     *
     */
    function buildCity(bytes calldata _proof) external virtual;

    /**
     * If the player's defense army is defeated(lost in battle)
     * the player calls this function to commit a new defense army.
     */
    function deployNewDefenseArmy(bytes calldata _proof) external virtual;

    /**
     * Attack a city by committing an attacking army.
     * @dev modifier isAttackable(_target)
     *
     * @param _target address - the address of an attackable city owner
     * @param _attackerArmy Army - the attack army of the player
     */
    function attack(address _target, Army memory _attackerArmy) external virtual;

    /**
     * Report the result of the clash between the player and his attacker.
     * - If the player defends his city then he wins points and he keeps his defending army private & unchanged.
     * - If the player loses then he is required to buildCity again.
     * - The player takes the attacker army and his army hash as a public input to prove his honesty.
     */
    function reportAttack(bool attacker_wins, bytes calldata _proof) external virtual;

    /**
     * Surrender when under attack
     * @dev modifier isUnderAttack
     *
     */
    function surrender() external virtual;

    /**
     * Claim win points when the opponent does not report the result of the clash within a certain time.
     * d
     */
    function lootCity() external virtual;

    /**
     * @return address - the address of an owner of a city in peace.
     */
    function findAttackableCity() external view virtual returns (address);

    /**
     * Return the player city state
     *
     * @param _player address - address of the player
     * @return _id uint256 - city identifier
     * @return _defenseArmyHash bytes32 - hashe of the player's defense army
     * @return _name bytes32 - the name of the city
     * @return _cityStatus CityStatus - the conflict status of the city
     * @return _points uint256 - the player's score
     * @return _attacker address - the address of the attacker(address(0) if CityStatus=InPeace)
     * @return _attackedAt uint256 - the time at which the player is attacked,
     * @return _target address - the target player address that is underAttack by this player,
     * @return _attackingArmy Army - the attack army
     */
    function playerState(address _player)
        external
        view
        virtual
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
        );
}
