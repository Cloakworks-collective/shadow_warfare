//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/metatx/ERC2771Context.sol";
import "./IVerifier.sol";

/**
 * Abstraction for Zero-Knowledge AutoBattler Game
 */
abstract contract IBattleshipGame is ERC2771Context {
    /// EVENTS ///

    event Joined(uint256 _nonce, address _by);
    event Clash(address _attacker, address _defender, uint256 _clash);
    event Won(address _winner, uint256 _nonce);
    event Destroyed(address _defender, uint256 _nonce);
    event Foreit(address _forfeiter, uint256 _nonce);

    /// STRUCTS ///

    enum CityStatus {
        NonExistant,
        InPeace,  
        UnderAttack,
        Destroyed,
        Defended, 
        Surrendered      
    }

    enum ArmyType {
        Tank,
        Artillery,
        Infantry
    }

    struct PlayerStatus {
        uint256 cityId;
        bytes32 cityArmyHash;
        CityStatus conflict;
        uint256 points;
        bytes32 targetCity;
        address attacked_by;
        ArmyType attaker_army;
    }

    struct GameRecord {
        uint256 nonce; // clash #
        mapping(address => PlayerStatus) player; // map player address to player status
        mapping(address => bytes32) attackable; // record of attackable fortresses
    }

    /// VARIABLES ///

    address public trustedForwarder; // make trusted forwarder public
    IArmyVerifier bv; // verifier for proving valid army rule compliance

    /// MODIFIERS ///

    /**
     * Determine whether message sender has registered of a fortress
     */
    modifier isPlayer(uint256 _game) {
        require(GameRecord.player[_msgSender()].cityArmyHash != bytes32(0), "Please register a city first!");
        _;
    }

    /**
     * Determine whether a player is allowed to build a new fortress(register a city)
     */
    modifier canBuild() {
        require(
            GameRecord.player[_msgSender()].conflict == CityStatus.NonExistant ||
            GameRecord.player[_msgSender()].conflict == CityStatus.Destroyed ||
            GameRecord.player[_msgSender()].conflict == CityStatus.Surrendered
            , "You already have a standing fortress!"
        );
        _;
    }

    /**
     * Ensure a message sender is not currently attacking another player
     * Default: null bytes instead of target's army hash
     */
    modifier canAttack() {
        require(GameRecord.play[_msgSender()].conflict == CityStatus.InPeace, "You city should be in peace for you to attack");
        require(GameRecord.player[_msgSender()].targetCity == bytes32(0), "You opponent did not report the clash result yet!");
        _;
    }

    /**
     * Ensure a message sender is under attack
     */
    modifier isUnderAttack() {
        require(GameRecord.play[_msgSender()].confict == CityStatus.UnderAttack, "You city is not under attack!");
        _;
    }

    /**
     * Ensure that a target fortress is attackable
     */
    modifier isAttackable(address _target) {
        // Check if the address is in the attackable mapping
        bool isAttackable = false;
        for (uint256 i = 0; i < GameRecord.attackable.length; i++) {
            if (GameRecord.attackable[i] == _target) {
                isAttackable = true;
            }
        }
        require(isAttackable == true, "Your target city is not attackable");
        _;
    }

    /**
     * Build a new fortress by commiting a defense army.
     * @dev modifier canBuild
     *
     * @param _proof bytes calldata - zk proof of valid board
     */
    function buildCity(bytes calldata _proof) external virtual;

    /**
     * Forfeit a clash if under attack
     * @dev modifier isUnderAttack
     *
     */
    function surrender() external virtual;

    /**
     * Attack a ciy in peace
     * @dev modifier isAttackable(_target)
     *
     * @param _target address - the address of the target city to attack

     */
    function attack(address _target) external virtual;

    /**
     * @return address - the address of an attackable fortress
     */
    function findAttackableFortress() external view returns (address);

    /**
     * Report the result of the clash between the player and his attacker.
     * If the player defends his city then he wins points and he keeps his defending army private & unchanged.
     * If the player loses then he is required to buildCity again.  
     * @note: the player takes the attacker army and his army hash as a public input to prove his honesty. 
     */
    function reportAttack(bytes calldata _proof, target) 
    

    /**
     * Return the player info
     *
     * @param _game uint256 - nonce of game to look for
     * @return _participants address[2] - addresses of host and guest players respectively
     * @return _boards bytes32[2] - hashes of host and guest boards respectively
     * @return _turnNonce uint256 - the current turn number for the game
     * @return _hitNonce uint256[2] - the current number of hits host and guest have scored respectively
     * @return _status GameStatus - status of the game
     * @return _winner address - if game is won, will show winner
     */
    function playerState(
        address player
    )
        external
        view
        virtual
        returns (
            address[2] memory _participants,
            bytes32[2] memory _boards,
            uint256 _turnNonce,
            uint256[2] memory _hitNonce,
            GameStatus _status,
            address _winner
        );
}