# CREATE2 Deterministic Factory (Celo)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Celo mainnet](https://img.shields.io/badge/Celo-deployed-gold)](https://celoscan.io/address/0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242)

Deploy any contract **deterministically** on **Celo mainnet** using `CREATE2`.  
This repo shows the exact steps (creation bytecode → init → address prediction → deploy) so anyone can reproduce and verify on-chain.

---

## Contracts & Addresses

- **Create2Factory (pre-deployed):**  
  `0xDE0E8fEb4b88aCfe02c2291BEca7c1fFb7721bFE`  
  ↗︎ https://celoscan.io/address/0xDE0E8fEb4b88aCfe02c2291BEca7c1fFb7721bFE

- **InitBuilder (helper to ABI-encode constructor):**  
  `0xA72e36A913356353699298BeDACe01bEed70deF8`  
  ↗︎ https://celoscan.io/address/0xA72e36A913356353699298BeDACe01bEed70deF8

- **Greeter (CREATE2 target, deterministic):**  
  `0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242` *(replace if you redeploy with another salt)*  
  ↗︎ https://celoscan.io/address/0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242

> Chain: **Celo Mainnet**

---

## Greeter.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Greeter {
    string private _greeting;

    constructor(string memory greeting_) {
        _greeting = greeting_;
    }

    function greeting() external view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string calldata g) external {
        _greeting = g;
    }
}
````

Compiler: 0.8.24, Optimizer enabled, Runs 200.

How it works (CREATE2 flow)

Compile Greeter.sol in Remix (0.8.24 / O=200).

In Compilation details → EVM → Bytecode → object, copy the creation bytecode (long 0x60…, not runtime).

On InitBuilder (0xA72e…), call:

encodeInit(creation, greeting) → returns:

init (creation bytecode + ABI-encoded constructor),

initHash = keccak256(init).

On Create2Factory (0xDE0E…):

computeAddress(bytes32 salt, bytes32 bytecodeHash) with your salt and initHash → predicted address,

deploy(bytes bytecode, bytes32 salt) with init and the same salt → actual deploy.

Deterministic formula

address = keccak256( 0xFF ++ factory ++ salt ++ keccak256(init) )[12:]

Reproduce (Remix quick steps)

Init code

Compile Greeter → copy Bytecode → object (creation).

InitBuilder → encodeInit(creation, "Hello from CREATE2")
Save:

init (long 0x…)

initHash (bytes32)

Predict

Example salt (bytes32):
0x0000000000000000000000000000000000000000000000000000000000000001

Factory → computeAddress(salt, initHash) → note the address.

Deploy

Factory → deploy(init, salt) → confirm MetaMask.

The emitted address must equal the predicted one.

Test

Greeter → At Address = deployed address → call greeting() / setGreeting("Hi!").

Verify on CeloScan (single file)

Compiler 0.8.24

Optimizer Yes (Runs: 200)

Constructor args = the exact string you passed (e.g. "Hello from CREATE2" or "")

Paste the source of Greeter.sol → Submit

Quick test (Ethers v6 in browser console)

// Paste into DevTools console on a page where MetaMask is available
const { ethers } = window;
(async () => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send('eth_requestAccounts', []);
  const signer = await provider.getSigner();
  const greeter = new ethers.Contract(
    "0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242", // replace if redeployed
    [
      "function greeting() view returns (string)",
      "function setGreeting(string g)"
    ],
    signer
  );
  console.log("greeting:", await greeter.greeting());
  const tx = await greeter.setGreeting("Hello Celo!");
  await tx.wait();
  console.log("updated:", await greeter.greeting());
})();

Troubleshooting

invalid BytesLike → a bytes field is empty or missing 0x.

Wrong address after deploy → salt or init changed; recompute and redeploy.

Revert on deploy → check:

init is creation bytecode + args (very long, starts 0x60…),

initHash = keccak256(init) (use a helper if needed),

predicted address is not already used (eth_getCode(addr) === "0x"),

gas limit is generous (2–3M).

License

MIT ©
