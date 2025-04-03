# Translation Verification Smart Contract

[![License: AFL-3.0](https://img.shields.io/badge/License-AFL--3.0-lightgrey.svg)](https://opensource.org/licenses/AFL-3.0)

A Solidity smart contract designed to manage and verify translations through a peer review and community voting process on the blockchain.

Collecting workspace information# Blockchain Translation Verification System

This repository contains a Solidity smart contract for verifying translations in a decentralized manner using blockchain technology.

## Overview

The TranslationVerification.sol contract implements a complete system for:
- Managing translation uploads
- Facilitating peer reviews
- Enabling community-based verification
- Handling disputes
- Distributing rewards to participants

## Key Features

- **Role-based Access Control**: Distinct roles for translators, reviewers, validators, and admins
- **Staking Mechanism**: Participants must stake ETH to participate, ensuring accountability
- **Multi-stage Verification**:
  - Initial translator submission
  - Peer review process
  - Community validation with reputation-weighted voting
- **Dispute Resolution**: Allows for challenging and resolving disputed translations
- **Reward System**: Configurable token or ETH rewards for translators and reviewers
- **Reputation System**: Validators gain or lose reputation based on their voting history

## Contract Structure

The contract includes:
- `Translation` struct for storing all translation-related data
- `Stake` struct to manage user stakes
- Role assignment and management functions
- Translation workflow functions (upload, review, verify)
- Dispute handling mechanisms
- Token reward distribution system

## Usage Flow

1. **Setup**: Admin assigns roles and sets parameters
2. **Staking**: Participants stake ETH to participate
3. **Translation**: Translators upload translation hashes
4. **Peer Review**: Reviewers evaluate and approve/reject translations
5. **Community Verification**: Validators vote on translations after peer reviews
6. **Rewards**: Successful translations trigger rewards for translators and reviewers

## Token Integration

The contract supports ERC20 token rewards with:
- Configurable reward amounts
- Optional toggle between token and ETH rewards
- Admin functions to manage token settings

## Security Notes

This contract requires:
- Proper configuration of the `totalValidators` parameter
- Implementation of the `findReviewer` function for production use
- Testing and possible audit before production deployment

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is licensed under the Academic Free License v3.0 - see the [LICENSE](LICENSE) file for details or check the SPDX identifier at the top of the contract file.
