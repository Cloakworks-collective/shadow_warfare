//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IArmyVerifier {
    function verify(bytes calldata) external view returns (bool r);
}

interface IAttackVerifier {
    function verify(bytes calldata) external view returns (bool r);
}
