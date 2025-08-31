# create2-deterministic-factory
Deploy any deterministic address contract bytecode with CREATE2

CREATE2 Greeter (Celo)

 

A minimal Greeter contract deployed deterministically on Celo mainnet using CREATE2.
This repo documents the exact steps (bytecode → init → address prediction → deploy) so anyone can reproduce and verify on-chain.


---

Contracts & Addresses

Create2Factory (pre-deployed):
0xDE0E8fEb4b88aCfe02c2291BEca7c1fFb7721bFE

InitBuilder (helper to ABI-encode constructor into init code):
0xA72e36A913356353699298BeDACe01bEed70deF8

Greeter (CREATE2 target) (deterministic address):
0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242 (replace if you redeploy with a different salt)


> Chain: Celo Mainnet (CELO)




---

Greeter.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Greeter {
    string private _greeting;
    constructor(string memory greeting_) { _greeting = greeting_; }
    function greeting() external view returns (string memory) { return _greeting; }
    function setGreeting(string calldata g) external { _greeting = g; }
}

Compiler: 0.8.24, Optimizer enabled, Runs 200.


---

How it works (CREATE2 flow)

1. Compile Greeter.sol in Remix (0.8.24 / O=200).


2. In Compilation details → EVM → Bytecode → object, copy the creation bytecode (the long hex starting with 0x60…, not runtime).


3. On InitBuilder (0xA72e…), call:

encodeInit(creation, greeting) → returns:

init (the full init code with ABI-encoded constructor),

initHash = keccak256(init).




4. On Create2Factory (0xDE0E…):

computeAddress(bytes32 salt, bytes32 bytecodeHash) with your salt and initHash → predicted address.

deploy(bytes bytecode, bytes32 salt) with init and the same salt → deploys to the predicted address.




> Deterministic formula:
addr = keccak256(0xFF ++ factory ++ salt ++ keccak256(init))[12:]




---

Reproduce (step-by-step in Remix)

1. Init code

Compile Greeter → copy Bytecode → object (creation).

InitBuilder → encodeInit(creation, "Hello from CREATE2")
Save:

init (long 0x…)

initHash (bytes32)




2. Predict

Salt example (bytes32):
0x0000000000000000000000000000000000000000000000000000000000000001

Factory → computeAddress(salt, initHash) → note the address.



3. Deploy

Factory → deploy(init, salt) → confirm in MetaMask.

The emitted address must equal the predicted one.



4. Test

Greeter → At Address = deployed address → call greeting() / setGreeting("Hi!").





---

Verify on CeloScan (single file)

Compiler: 0.8.24

Optimizer: Yes (Runs: 200)

Constructor arguments: the exact string you passed (e.g. "Hello from CREATE2" or "")

Paste the source of Greeter.sol and submit.



---

Quick Ethers v6 snippet (browser console)

<script src="https://cdn.jsdelivr.net/npm/ethers@6.12.0/dist/ethers.umd.min.js"></script>
<script>
(async () => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send('eth_requestAccounts', []);
  const signer = await provider.getSigner();
  const greeter = new ethers.Contract(
    "0x6FddC83BB0F19597a6AeE9a8BE8b2548F02dC242", // replace if needed
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
</script>


---

Troubleshooting

invalid BytesLike → a bytes field is empty or missing 0x.

Wrong address after deploy → salt or init changed; recompute and redeploy.

Revert on deploy → check:

init is the creation bytecode + args (very long, starts 0x60…),

initHash = keccak256(init) (use a helper if needed),

the predicted address is not already in use (eth_getCode(addr) === "0x"),

gas limit is generous (2–3M in Remix UI).
License

MIT © You (see LICENSE)
