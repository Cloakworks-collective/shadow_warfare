// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                        IMPORTS
//////////////////////////////////////////////////////////////*/
import "./utils/constants.sol";
import "./utils/customTypes.sol";

/*//////////////////////////////////////////////////////////////
                        INTERFACE
//////////////////////////////////////////////////////////////*/
interface INoirVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

contract AutoBattler {

    /*//////////////////////////////////////////////////////////////
                        ERRORS
    //////////////////////////////////////////////////////////////*/
    error ErrorInvalidProof();
    error ErrorInvalidAttack();

    /*//////////////////////////////////////////////////////////////
                        IMMUTABLES VARIABLES
    //////////////////////////////////////////////////////////////*/
    INoirVerifier public immutable validDefenseVerifier;
    INoirVerifier public immutable revealAttackVerifier;

    /*//////////////////////////////////////////////////////////////
                                Mappings and Arrays
    //////////////////////////////////////////////////////////////*/
    Battle[] public battles;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event DefenseVerified(address indexed _defender, uint256 indexed cityId);
    event AttackRevealed(address indexed _attacker, uint256 indexed cityId);
    event BattleResult(address indexed _attacker, uint256 indexed cityId, bool _win);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyCityOwner() {
        _;
    }

    modifier onlyValidPlayer() {
        _;
    }


    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _validDefenseVerifier,
        address _revealAttackVerifier
    ) {
        validDefenseVerifier = INoirVerifier(_validDefenseVerifier);
        revealAttackVerifier = INoirVerifier(_revealAttackVerifier);
    }

    /*//////////////////////////////////////////////////////////////
                             USER ACTIONS
    //////////////////////////////////////////////////////////////*/

    function commitDefense(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external {
        require(validDefenseVerifier.verify(_proof, _publicInputs), "Invalid defense proof");
        emit DefenseVerified(msg.sender, uint256(_publicInputs[0]));
    }

    function commitAttack(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external {
        require(revealAttackVerifier.verify(_proof, _publicInputs), "Invalid attack proof");
        emit AttackRevealed(msg.sender, uint256(_publicInputs[0]));
    }

    function verifyDefense(
        uint256 _cityId
    ) external {
        emit BattleResult(msg.sender, _cityId, true);
    }

    function collectForfeit(
        uint256 _cityId
    ) external {
        emit BattleResult(msg.sender, _cityId, false);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNALS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                GETTERS 
    //////////////////////////////////////////////////////////////*/

    function getCityOwner(uint256 _cityId) external view returns (address) {
        return address(0);
    }

    function getCityDefense(uint256 _cityId) external view returns (bytes32) {
        return bytes32(0);
    }

}

