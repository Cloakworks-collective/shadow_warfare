// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                        IMPORTS
//////////////////////////////////////////////////////////////*/
import "./City.sol";
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
    error ErrorUnauthorized();

    /*//////////////////////////////////////////////////////////////
                        IMMUTABLES VARIABLES
    //////////////////////////////////////////////////////////////*/
    INoirVerifier public immutable validDefenseVerifier;
    INoirVerifier public immutable revealAttackVerifier;
    City public immutable city;

    /*//////////////////////////////////////////////////////////////
                                Mappings and Arrays
    //////////////////////////////////////////////////////////////*/
    Battle[] public battles;
    mapping(address => bytes) public defenseHashes;


    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event DefenseVerified(address indexed _defender, uint256 indexed cityId);
    event AttackRevealed(address indexed _attacker, uint256 indexed cityId);
    event BattleResult(address indexed _attacker, uint256 indexed cityId, bool _win);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyCityOwner(uint256 cityId) {
        if (city.ownerOf(cityId) != msg.sender) {
            revert ErrorUnauthorized();
        }
         _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _validDefenseVerifier,
        address _revealAttackVerifier, 
        address _city
    ) {
        validDefenseVerifier = INoirVerifier(_validDefenseVerifier);
        revealAttackVerifier = INoirVerifier(_revealAttackVerifier);
        city = City(_city);
    }

    /*//////////////////////////////////////////////////////////////
                             USER ACTIONS
    //////////////////////////////////////////////////////////////*/

    // player 1 commits defense
    // player 1 defense is verified
    // player1 defense hash is stored in the contract
    function commitDefense(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external  onlyCityOwner(params.cityId){
        require(validDefenseVerifier.verify(_proof, _publicInputs), "Invalid defense proof");
        emit DefenseVerified(msg.sender, uint256(_publicInputs[0]));
    }

    // player 2 commits attack
    // on chain verification of the attack (no circuits involved)
    function commitAttack(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external  onlyCityOwner(params.cityId) {
        require(revealAttackVerifier.verify(_proof, _publicInputs), "Invalid attack proof");
        emit AttackRevealed(msg.sender, uint256(_publicInputs[0]));
    }

    // re verify defense
    // just check hash of defense
    function verifyDefense(
        uint256 _cityId
    ) external  onlyCityOwner(params.cityId) {
        emit BattleResult(msg.sender, _cityId, true);
    }

    // collect the forfeit, defense was not verified in time (24 hours after attack was cimmited)
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

}

