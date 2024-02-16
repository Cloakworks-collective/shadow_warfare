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
    event Surrendered(address _winner, uint256 _nonce);

    /// ENUMS ///

    enum CityStatus {
        NonExistant,
        InPeace,  
        UnderAttack,
        Destroyed,
        Defended, 
        Surrendered      
    }

    enum Faction {
        Red,
        Blue,
        Green
    }

    enum ArmyType {
        Tank,
        Artillery,
        Infantry
    }

    /// STRUCTS ///
    
    struct Army {
        uint256 tank;
        uint256 artillery;
        uint256 infantry;
    }

    struct City {
        uint256 id;
        bytes32 cityArmyHash;
        bytes32 name;
        CityStatus conflict;
        Faction faction;
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
        mapping(address => bytes32) attackable; // record of attackable cities
    }

    /// VARIABLES ///

    IArmyVerifier public av; // verifier for proving valid army rule compliance
    IAttackVerifier public sv; // verifier for proving attack report honesty

    /// MODIFIERS ///

    /**
     * Determine whether message sender has registered of a fortress
     */
    modifier isPlayer() {
        require(GameRecord.player[msg.sender].cityArmyHash != bytes32(0), "Please register a city first!");
        _;
    }

    /**
     * Determine whether a player is allowed to build a defending city
     */
    modifier canBuild() {
        require(
            GameRecord.player[msg.sender].conflict == CityStatus.NonExistant ||
            GameRecord.player[msg.sender].conflict == CityStatus.Destroyed ||
            GameRecord.player[msg.sender].conflict == CityStatus.Surrendered
            , "You already have a defending city!"
        );
        _;
    }

    /**
     * Ensure a message sender is not currently attacking another player
     * Default: null bytes instead of target's army hash
     */
    modifier canAttack() {
        require(GameRecord.play[msg.sender].conflict == CityStatus.InPeace, "You city should be in peace for you to attack");
        require(GameRecord.player[msg.sender].targetCity == bytes32(0), "You opponent did not report the clash result yet!");
        _;
    }

    /**
     * Ensure a message sender is under attack
     */
    modifier isUnderAttack() {
        require(GameRecord.play[msg.sender].confict == CityStatus.UnderAttack, "You city is not under attack!");
        _;
    }

    /**
     * Ensure that a target city is attackable
     */
    modifier isAttackable(address _target) {
        // Check if the address is in the attackable mapping
        bool attackable = false;
        for (uint256 i = 0; i < GameRecord.attackable.length; i++) {
            if (GameRecord.attackable[i] == _target) {
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
     * @param _proof bytes calldata - zk proof of valid board
     * @param name bytes32 name - name of the city
     * @param faction uint8 - faction of the city
     */
    function buildCity(
        bytes32 name, 
        Faction faction,
        bytes calldata _proof
    ) external virtual;

    /**
     * Defends the city by commiting a defense army.
     * @dev modifier canBuild
     *
     * @param _proof bytes calldata - zk proof of valid board
     */
    function defendCity(bytes calldata _proof) public virtual;

    /**
     * Attack a city by committing an attacking army.
     * @dev modifier isAttackable(_target)
     *
     * @param _target uint256 - the id of the target city to attack

     */
    function attack(uint256 _target) external virtual;

    /**
     * Report the result of the clash between the player and his attacker.
     * If the player defends his city then he wins points and he keeps his defending army private & unchanged.
     * If the player loses then he is required to buildCity again.  
     * the player takes the attacker army and his army hash as a public input to prove his honesty. 
     */

    function reportAttack(bytes calldata _proof) external virtual;


    /**
     * Surrender when under attack
     * @dev modifier isUnderAttack
     *
     */
    function surrender() external virtual;


    /**
     * Claim forfeit when the opponent does not report the result of the clash within a certain time.
     *
     */
    function claimSurrender() external virtual;    

    /**
     * @return address - the address of an attackable fortress
     */
    function findAttackableFortress() external view returns (address);


    // /**
    //  * Return the player info
    //  *
    //  * @param _game uint256 - nonce of game to look for
    //  * @return _participants address[2] - addresses of host and guest players respectively
    //  * @return _boards bytes32[2] - hashes of host and guest boards respectively
    //  * @return _turnNonce uint256 - the current turn number for the game
    //  * @return _hitNonce uint256[2] - the current number of hits host and guest have scored respectively
    //  * @return _status GameStatus - status of the game
    //  * @return _winner address - if game is won, will show winner
    //  */
    // function playerState(
    //     address player
    // )
    //     external
    //     view
    //     virtual
    //     returns (
    //         address[2] memory _participants,
    //         bytes32[2] memory _boards,
    //         uint256 _turnNonce,
    //         uint256[2] memory _hitNonce,
    //         GameStatus _status,
    //         address _winner
    //     );
}