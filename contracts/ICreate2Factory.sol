// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICreate2Factory {
  function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address);
  function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address);
}
