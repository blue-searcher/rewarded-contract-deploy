# rewarded-contract-deploy

- Call `request{value: X}(bytes memory _bytecode)` to express your interest in deploying the supplied bytecode on-chain. ETH value provided to this transaction is handled as a reward to any external actor willing to deploy your contract. Each `request` creates a new `DeployRequest` identified by an id.

- Any request can be canceled with `cancel(uint256 _id)` which returns the reward back.

- Anyone can call `deploy(uint256 _id)` to deploy a contract and become eligible to withdraw the corresponding reward. 

- Call `withdraw()` to withdraw collected rewards.


The bytecode must include constructor arguments too.


Inspired by a [tweet from 0xtuba](https://twitter.com/0xtuba/status/1638230894941970465).
