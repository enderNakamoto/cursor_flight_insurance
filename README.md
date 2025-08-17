Here is the improved README **without any code blocks**, fully copy-pasteable into your Markdown editor:

---

# ✈️ Flight Delay Insurance Protocol

A decentralized, parametric insurance platform that allows travelers to hedge against long flight delays with fixed-premium coverage. Built on Ethereum using ERC-4626 vaults and Acurast oracles.

---

## 🧩 How It Works

Travelers pay a fixed premium of **50 USDC** for flight delay coverage. If the flight is delayed by **6+ hours**, they receive a **200 USDC payout**, automatically settled via secure, real-world data from Acurast oracles.

Investors supply capital through ERC‑4626-compliant vaults, earning yield from premiums and keeping capital from non-claimed policies. Capital efficiency is enforced via a 4:1 coverage ratio.

---

## 🏗️ Protocol Architecture

Traveler ➝ Buy policy
Investor ➝ Provide capital

FlightInsurance (connected to Acurast TEE oracle) controls:

* HedgeVault (per-flight, holds collateral)
* RiskVault (ERC-4626, investor capital pool)

---

## ✨ Features

* 💸 **Fixed-premium insurance**: 50 USDC premium, 200 USDC payout
* ✈️ **6+ hour delay triggers automatic payout**
* 🏦 **ERC-4626 compliant RiskVaults** for investor participation
* 🔐 **Per-flight HedgeVaults** for coverage separation
* 📈 **4:1 capital backing ratio**
* 🧠 **Oracle-based automated settlement** via [Acurast](https://acurast.com/)
* ⏰ **24-hour policy expiration** after flight time

---

## 🔧 Tech Stack

Frontend: Next.js 14, TypeScript, Tailwind CSS, shadcn/ui
Smart Contracts: Solidity, Foundry
Wallet Integration: Dynamic
Oracle: Acurast

---

## 📦 Smart Contracts

* **FlightInsurance.sol**: Main insurance controller
* **RiskVault.sol**: ERC-4626 vault for capital providers
* **HedgeVault.sol**: Per-flight vault for policy backing

---

## 🛠️ Getting Started

**Prerequisites:** Node.js 18+, Foundry, Git

1. Clone the repo: `git clone <repository-url> && cd cursor_insurance`
2. Install dependencies: `npm install`
3. Install Foundry contracts: `forge install OpenZeppelin/openzeppelin-contracts`
4. Copy `.env.example` to `.env` and configure it
5. Compile contracts: `forge build`
6. Run tests: `forge test`
7. Start dev server: `npm run dev`

---

## 🧪 Testing

**Smart Contracts**

* `forge test` – Run all tests
* `forge test -vvv` – Verbose mode
* `forge test --match-test testCreatePolicy` – Specific test

**Frontend**

* `npm run lint` – Linting
* `npm run type-check` – TypeScript check

---

## 🗂 Project Structure

* `src/` – Frontend app (Next.js, components, hooks, types, etc.)
* `contracts/` – Solidity contracts (`core/`, `interfaces/`, `libraries/`, `mocks/`)
* `scripts/` – Deployment scripts
* `test/` – Smart contract test cases
* `docs/` – Documentation
* `public/` – Static assets

---

## 📚 Documentation

* [Implementation Plan](./docs/Implementation.md)
* [Project Structure](./docs/project_structure.md)
* [UI/UX Design](./docs/UI_UX_doc.md)
* [Bug Tracker](./docs/Bug_tracking.md)

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add feature'`
4. Push and open a PR: `git push origin feature/your-feature`

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE)

---

## 📈 Roadmap

**Phase 1: Core Protocol**

* ✅ Project scaffolding
* ⬜ FlightInsurance, RiskVault, HedgeVault contracts
* ⬜ Oracle integration

**Phase 2: Frontend**

* ⬜ Policy dashboard
* ⬜ Investment interface
* ⬜ Flight monitoring

**Phase 3: Production Launch**

* ⬜ Audits
* ⬜ Deployment
* ⬜ Onboarding & docs
* ⬜ Community rollout

---

## 🛡️ Security

This project is in active development. **Do not use with real funds** until audited.

---

## 💬 Support

* Create an issue on GitHub
* Check `/docs` folder
* Refer to `Implementation.md` for progress

---

Let me know if you'd like a PDF or HTML version next.
