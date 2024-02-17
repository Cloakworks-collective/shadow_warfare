//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IAutoBattler.sol";

contract BattleshipGame is IAutoBattler {
    /// CONSTRUCTOR ///

    /**
     * Construct new instance of Battleship manager
     *
     * @param _forwarder address - the address of the erc2771 trusted forwarder (NOT RELATED TO NOIR)
     * @param _bv address - the address of the initial army validity prover
     * @param _sv address - the address of the attack report prover
     */
    constructor(
        address _forwarder,
        address _bv,
        address _sv
    ) ERC2771Context(_forwarder) {
        trustedForwarder = _forwarder;
        bv = IBoardVerifier(_bv);
        sv = IShotVerifier(_sv);
    }

    /// FUNCTIONS ///

    

    /// VIEWS ///


    /// INTERNAL ///

}