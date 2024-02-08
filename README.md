# WSDM Token

![License](https://img.shields.io/badge/License-GPL--3.0-orange)
![Hardhat](https://img.shields.io/badge/hardhat-^2.12-blue)

This repository contains several Ethereum smart contracts for different purposes.
<br/>

## About Wisdomise

[![Wisdomise Logo](https://wisdomise.com/_next/static/media/logo.9e5d16bb.svg)](https://wisdomise.com/)

Wisdomise is a distributed team with a global presence, and AI is at the core of our operations. As a Swiss AI company, we are at the forefront of revolutionizing finance and decentralized economies. Our focus is on providing innovative software solutions for wealth management, catering to both retail and institutional clients.

### CeDeFi Wealth Management Platform

At the heart of our offerings is the CeDeFi Wealth Management Platform. This groundbreaking platform empowers investors to manage their assets seamlessly through a combination of CeFi (Centralized Finance) and DeFi (Decentralized Finance) products. It represents a paradigm shift in how individuals and institutions engage with and grow their wealth.

### Wisdomise Token (WSDM)

Integral to our ecosystem is the Wisdomise token (WSDM). This token plays a crucial role in facilitating transactions and interactions within our platform. It serves as a key element in our innovative approach to merging traditional finance with the decentralized world.

### Future Expansion

As we continue to evolve, our vision extends beyond digital assets. We are committed to expanding our solutions to encompass a broader spectrum of financial instruments, further solidifying our position as leaders in the ever-changing landscape of decentralized finance.

## Contracts

### 1. wsdm.sol

Wisdomise Token (WSDM) is an ERC-20 token designed to bring wisdom and innovation to the decentralized space. The token leverages the OpenZeppelin library, implementing both the standard ERC-20 and ERC-20 permit extensions. WSDM has a total supply of 1 billion tokens, with a fixed decimal precision of 6.

The contract is constructed with an initial reserve address to which the entire token supply is minted upon deployment.

WSDM incorporates permit functionality, allowing users to approve token transactions using a signature, enhancing the user experience by simplifying the approval process for delegated transfers. The contract is deployed with the name "Wisdomise" and the symbol "WSDM" for easy identification within the Ethereum ecosystem.

### 2. vesting.sol

**Vesting Contract for WSDM Tokens**

The Vesting contract is specifically designed for the Wisdomise Token (WSDM). It extends the OpenZeppelin VestingWallet contract to manage the controlled release of WSDM tokens to beneficiaries over a predefined vesting schedule.


### 3. TokenMigration.sol

The Token Migration contract facilitates the migration of temporary Wisdomise Tokens (TWSDM) for users, allowing them to burn these temporary tokens and receive WSDM tokens according to a predefined vesting schedule. This process is designed to transition from temporary token holdings to fully vested WSDM tokens.

### 4. TokenDistributor.sol

The Token Distributor contract manages the distribution of Wisdomise Tokens (WSDM) to various payees. It is designed to handle payments to different accounts based on predefined shares.

### 5. locking.sol

The Locking contract is designed for Wisdomise Tokens (WSDM). It provides a locking mechanism for WSDM token holders with customizable penalty fees, withdrawal periods, and free unlock durations.
#### Key Features:

1. **Token Locking:** Users can lock their Wisdomise Tokens, preventing them from being transferred during the lock period.

2. **Customizable Penalty Fees:** The contract supports customizable penalty fees based on the duration of the lock. This flexibility allows project owners to tailor penalties according to their tokenomics strategy.

3. **Withdrawal Periods:** Users can withdraw their locked tokens after a specified withdrawal period. This feature ensures that locked tokens are not immediately accessible, promoting long-term commitment.

4. **Emergency Exit:** In emergency situations, an emergency exit feature allows users to quickly withdraw their tokens. This provides an extra layer of security in unforeseen circumstances.

5. **Pausing Mechanism:** The contract includes a pausing mechanism, allowing the pauser (typically the contract owner) to halt certain functionalities if necessary. This feature can be useful in cases of security vulnerabilities or protocol upgrades.

6. **Free Trial Periods:** Users may have free trial periods where no penalties are applied. This encourages users to try out the locking feature without immediate consequences.

## Connect with Wisdomise

<div class="contents max-md:grid max-md:grid-cols-2 max-md:gap-3">
  <a class="mt-7 text-base max-md:mt-0" href="https://t.me/+eV_bqtiJbHo5NmI0">
    <img alt="Telegram" src="https://img.shields.io/badge/Telegram-blue?style=for-the-badge&logo=telegram" />
  </a>
  <a class="text-base" href="https://x.com/wisdomise">
    <img alt="Twitter" src="https://img.shields.io/badge/Twitter/X-blue?style=for-the-badge&logo=twitter" />
  </a>
  <a class="text-base" href="https://discord.com/invite/cqxSCGJt7d">
    <img alt="Discord" src="https://img.shields.io/badge/Discord-blue?style=for-the-badge&logo=discord" />
  </a>
  <a class="text-base" href="https://www.instagram.com/wisdomiseai/">
    <img alt="Instagram" src="https://img.shields.io/badge/Instagram-blue?style=for-the-badge&logo=instagram" />
  </a>
</div>