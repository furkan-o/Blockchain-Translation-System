# Translation Verification Smart Contract

[![License: AFL-3.0](https://img.shields.io/badge/License-AFL--3.0-lightgrey.svg)](https://opensource.org/licenses/AFL-3.0)

A Solidity smart contract designed to manage and verify translations through a peer review and community voting process on the blockchain.

## Overview

This contract provides a basic framework for tracking translations (represented by their hash) and subjecting them to a verification process. The process involves:

1.  **Uploading:** A translator submits the hash of their translation.
2.  **Peer Review:** A designated peer reviewer assesses the translation and provides an initial approval or rejection.
3.  **Community Verification:** If the peer review is positive, the wider community can vote to approve or reject the translation. A translation is considered finally verified if it reaches a required threshold of approvals based on the total number of validators.

**Note:** This contract stores only the *hash* of the translation, not the translation content itself. The assumption is that the translation content is stored off-chain (e.g., on IPFS or a traditional database), and its hash is used for on-chain verification.

## Features

* **Upload Translations:** Register a new translation hash on the blockchain.
* **Peer Review:** Record a single peer review decision (approve/reject).
* **Community Voting:** Allow multiple participants (validators/community members) to vote on a peer-reviewed translation.
* **Verification Logic:** Automatically determine the final verification status based on vote counts and a predefined threshold.
* **Event Emission:** Emits events for key actions (upload, peer review, final verification) for off-chain monitoring.

## Workflow

1.  **Upload:** A user calls `uploadTranslation(string memory hash)` with the unique hash of the translation content.
2.  **Peer Review:** Another user (intended to be a peer reviewer) calls `peerReviewTranslation(string memory hash, bool approve)`. This marks the translation as peer-reviewed and records the first approval or rejection.
3.  **Community Verification:** If the translation was peer-reviewed *and* received an initial approval (`approvals > 0`), other users can call `communityVerifyTranslation(string memory hash, bool approve)` to cast their vote. Each address can only vote once per translation.
4.  **Final Verification:** After each community vote, the contract checks if the verification threshold (`totalValidators / 2 + 1` approvals) has been met or if rejections decisively outweigh approvals. If either condition is met, the `verified` status is set, and the `FinalVerified` event is emitted.

## Contract Details

### State Variables

* `translations`: `mapping(string => Translation)` - Stores the details for each translation, keyed by its hash.
* `Translation` (struct): Contains information about a specific translation:
    * `translator`: Address of the original uploader.
    * `hash`: The translation hash string.
    * `peerReviewer`: Address of the user who performed the peer review.
    * `peerReviewed`: Flag indicating if the peer review step is complete.
    * `approvals`: Count of approval votes (includes the peer review approval if applicable).
    * `rejections`: Count of rejection votes (includes the peer review rejection if applicable).
    * `verified`: Final verification status (true if approved, false if rejected by threshold).
    * `hasVoted`: `mapping(address => bool)` - Tracks which addresses have already voted in the community verification stage.
* `validatorReputation`: `mapping(address => uint8)` - **Declared but currently unused in the contract logic.** Intended to track the reputation of validators.
* `totalValidators`: `uint8` - **Declared but not initialized or updated within the contract.** Represents the total number of validators used to calculate the approval threshold. **This value must be set externally or via an additional function (not included) for the community verification logic to work correctly.**

### Functions

* `uploadTranslation(string memory hash)`: Public function to upload a new translation hash. Requires the hash to not exist already.
* `peerReviewTranslation(string memory hash, bool approve)`: Public function to perform the peer review. Requires the translation to exist and not be previously peer-reviewed.
* `communityVerifyTranslation(string memory hash, bool approve)`: Public function for community members to vote. Requires the translation to exist, be peer-reviewed with at least one approval, and the caller must not have voted previously. Calculates final verification status based on votes vs. `totalValidators`.

### Events

* `TranslationUploaded(address indexed translator, string hash)`: Emitted when a translation hash is successfully uploaded.
* `PeerReviewed(string hash, address indexed reviewer, bool approved)`: Emitted when a peer review is submitted.
* `FinalVerified(string hash, bool approved)`: Emitted when the final verification status is determined (either approved by reaching the threshold or rejected).

## How to Use / Deployment

1.  **Compile:** Use a Solidity compiler compatible with `^0.8.0` (e.g., `solc`).
2.  **Deploy:** Deploy the compiled contract to an Ethereum-compatible blockchain (e.g., using tools like Remix, Hardhat, Truffle, or Foundry).
3.  **Set `totalValidators`:** **Crucially, after deployment, the `totalValidators` variable needs to be set.** Since the provided contract lacks a function to do this, you would either need to:
    * Modify the contract to include a setter function (e.g., `setTotalValidators(uint8 _count)`), potentially restricted to an owner/admin role.
    * Set the value during contract construction by modifying the constructor (currently implicit and empty).
4.  **Interact:** Users can then interact with the deployed contract by calling its public functions (`uploadTranslation`, `peerReviewTranslation`, `communityVerifyTranslation`) using a wallet or web3 library.

## Important Considerations & Caveats

* **`totalValidators` Initialization:** The contract is **unusable** for community verification as-is because `totalValidators` is never set. This variable *must* be initialized for the threshold calculation in `communityVerifyTranslation` to be meaningful.
* **Unused `validatorReputation`:** The `validatorReputation` mapping is declared but never read from or written to in the current logic.
* **Access Control:** There is no access control on who can call `peerReviewTranslation` or `communityVerifyTranslation`. Any address can act as a peer reviewer (only the first one counts) or a community voter (one vote per address). In a real-world scenario, you would likely want role-based access control (e.g., only registered reviewers can peer review, only registered validators can vote).
* **Single Peer Reviewer:** The current logic only allows for one peer review action per translation.
* **Off-Chain Data:** The actual translation content is managed off-chain. This contract only verifies the integrity/acceptance of a specific version represented by its hash.
* **Gas Costs:** Storing strings (hashes) and multiple mappings can incur gas costs. Ensure the design is suitable for your target blockchain and usage patterns.

## Potential Future Improvements

* Add a role system (e.g., Owner/Admin, Translator, Reviewer, Validator).
* Implement a function to set/update `totalValidators` (restricted to Admin).
* Integrate the `validatorReputation` system into the voting mechanism (e.g., weighted voting).
* Allow for multiple peer reviewers before opening to community voting.
* Implement a mechanism to handle disputes or challenges.
* Add staking or incentive mechanisms for translators, reviewers, and validators.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is licensed under the Academic Free License v3.0 - see the [LICENSE](LICENSE) file for details or check the SPDX identifier at the top of the contract file.
