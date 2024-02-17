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

    enum FortressStatus {
        NonExistant,
        InPeace,  
        UnderAttack,
        Destroyed,
        Surrendered      
    }

    enum ArmyType {
        Tank,
        Artillery,
        Infantry
    }

    struct PlayerStatus {
        uint256 cityId;
        bytes32 fortressArmy;
        FortressStatus confict;
        uint256 points;
        bytes32 targetFortress;
        bytes32 attacked_by;
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
        require(GameRecord.player[_msgSender()].fortressArmy != bytes32(0), "Please register a city first!");
        _;
    }

    /**
     * Determine whether a player is allowed to build a new fortress(register a city)
     */
    modifier canBuild() {
        require(
            GameRecord.play[_msgSender()].confict == FortressStatus.NonExistant ||
            GameRecord.play[_msgSender()].confict == FortressStatus.Destroyed ||
            GameRecord.play[_msgSender()].confict == FortressStatus.Surrendered
            , "You already have a standing fortress!"
        );
        _;
    }

    /**
     * Ensure a message sender is not currently attacking another player
     * Default: null bytes instead of target's army hash
     */
    modifier canAttack() {
        require(GameRecord.play[_msgSender()].confict == FortressStatus.InPeace, "You city should be in peace for you to attack");
        require(GameRecord.player[_msgSender()].targetFortress == bytes32(0), "You opponent did not report the clash result yet!");
        _;
    }

    /**
     * Ensure a message sender is under attack
     */
    modifier isUnderAttack() {
        require(GameRecord.play[_msgSender()].confict == FortressStatus.UnderAttack, "You city is not under attack!");
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
        require(isAttackable == true, "Your target fortress is not attackable");
        _;
    }

    /**
     * Register a new city by uploading a valid fortress army
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
    function surrender(uint256 _game) external virtual;

    /**
     * Attack a fortress in peace
     * @dev modifier isAttackable(_taret)
     *
     * @param _target address - the address of the target fortress to attack

     */
    function attack(address _target) external virtual;

    /**
     * @return address - the address of an attackable fortress
     */
    function findAttackableFortress() external view returns (address);


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