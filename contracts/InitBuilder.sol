// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract InitBuilder {
    function encodeInit(bytes calldata creation, string calldata greeting)
        external pure returns (bytes memory init, bytes32 initHash)
    {
        bytes memory args = abi.encode(greeting);
        init = bytes.concat(creation, args);
        initHash = keccak256(init);
    }
}
