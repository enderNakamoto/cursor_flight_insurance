# Product Requirements Document
## Flight Delay Insurance Protocol

### 📋 Project Overview
**Project Name**: Flight Delay Insurance Protocol  
**Project Type**: web3-dapp  
**Target Audience**: consumers  
**Description**: Decentralized insurance protocol where travelers pay 50 USDC for flight delay coverage (200 USDC payout) and investors provide capital through ERC4626 vaults to earn premiums and coverage amounts from non-claimed policies.

### 🏗️ Technical Architecture

#### Tech Stack
- **Frontend**: Next.js, Tailwind CSS, shadcn/ui
- **Backend**: Smart Contracts

- **Smart Contract Language**: Solidity
- **Smart Contract Development Stack**: Foundry

#### Web3 Configuration
- **Wallet Integration**: Dynamic
- **Multi-Chain Support**: Multi-chain
- **Cross-Chain Solution**: LayerZero
- **Oracle Solution**: Acurast

### 🎯 Core Features
- Fixed-price insurance: 50 USDC premium, 200 USDC payout
- Flight delay threshold: 6+ hours triggers payout
- ERC4626 risk vault for investor capital
- Per-flight hedge vaults for insurance policies
- 4:1 capital ratio requirement (200 USDC backing per 50 USDC insurance)
- Oracle-based automatic claim settlement
- 24-hour policy expiration after flight time
- Cross-chain vault operations via LayerZero

### 📅 Development Phases

#### Phase 1
Core smart contracts on single chain (Base testnet): FlightInsurance controller, RiskVault, HedgeVault. Basic insurance purchase and investor deposit flows. Oracle integration for flight status with updates every 5 minutes. Complete single-chain MVP.

#### Phase 2
Multi-chain expansion using LayerZero: Deploy vaults on different chains (Base + Arbitrum testnets). Implement cross-chain communication for capital management and claim settlements. Risk vault on one chain, hedge vaults distributed across chains.

#### Phase 3
Frontend development: Dashboard for policy management and investment tracking. User interfaces for cross-chain operations. Flight status monitoring. Complete testnet MVP with full user experience.

### 🎨 User Experience Design

#### User Journeys & Page Structure
Main Navigation: Buy Insurance | Invest | Dashboard | Flight Status  
Insurance Flow: Enter flight details → View premium (50 USDC) → Connect wallet → Approve USDC → Confirm purchase → Receive vault shares  
Investment Flow: Connect wallet → View current APY → Deposit USDC to risk vault → Receive vault shares → Monitor portfolio  
Claim Flow: Automatic detection of 6+ hour delay → Money moves from risk to hedge vault, and users can burn vault shares to get their money  

Key User Flows:

- Flight lookup: Enter flight number/route, see instant pricing
- Policy dashboard: Active policies, claim status, payout history
- Investment dashboard: Deposited capital, earned premiums, risk exposure
- Cross-chain operations: Seamless vault interactions across chains

#### Key User Flows
- **Landing Page**: User's first impression and entry point
- **Navigation**: How users move between pages and features
- **Core Actions**: Primary user interactions and goals
- **Onboarding**: New user experience and feature discovery

### 👥 Target Audience
Primary Audience: Travelers and crypto investors

User Personas:

- Frequent Traveler (insurance buyers)
  - Demographics: Business travelers, crypto users, vacation travelers, crypto-curious
  - Use Cases: Wants simple flight delay protection

- DeFi Investor (counterparty risk takers)
  - Demographics: Yield farmers, portfolio diversifiers
  - Technical Level: Advanced DeFi knowledge
  - Use Cases: Seeks yield from insurance premiums

#### User Personas
- **Demographics**: Based on target audience selection
- **Technical Level**: Varies by audience type
- **Use Cases**: Specific to project requirements

### 🔧 Additional Context & Requirements
- **Smart Contract Modularity**: Monolithic - Each hedge vault is deployed as a full contract instance.
- **Oracle Update Frequency**: Every 5 minutes.
- **Automatic Claim Settlement**: Oracle pushes data to the controller, which is checked by a keeper. If a delay is detected, funds are moved from risk to hedge vault.
- **Capital Ratio Enforcement**: Insurance cannot be purchased unless the 4:1 capital ratio is met.
- **ERC Standards**: ERC20 for all assets.
- **Capital Management**: 4:1 ratio enforcement across chains, withdrawal limits during active policies.

This refined PRD is now ready for engineering execution, with clarified technical decisions, scoped MVP features, and detailed architecture specifications.