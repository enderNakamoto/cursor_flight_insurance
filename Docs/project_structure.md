# Project Structure

## Root Directory
```
cursor_insurance/
├── src/
│   ├── app/                    # Next.js App Router pages
│   ├── components/             # Reusable React components
│   ├── lib/                    # Utility functions and configurations
│   ├── hooks/                  # Custom React hooks
│   ├── types/                  # TypeScript type definitions
│   └── styles/                 # Global styles and Tailwind config
├── contracts/                  # Solidity smart contracts
├── scripts/                    # Deployment and utility scripts
├── test/                       # Smart contract tests
├── docs/                       # Project documentation
├── public/                     # Static assets
├── .env.example               # Environment variables template
├── .gitignore                 # Git ignore rules
├── package.json               # Frontend dependencies
├── foundry.toml              # Foundry configuration
├── tailwind.config.js        # Tailwind CSS configuration
├── tsconfig.json             # TypeScript configuration
└── README.md                 # Project overview
```

## Detailed Structure

### Frontend Structure (`src/`)
```
src/
├── app/                       # Next.js App Router
│   ├── layout.tsx            # Root layout component
│   ├── page.tsx              # Landing page
│   ├── buy-insurance/        # Insurance purchase flow
│   │   └── page.tsx
│   ├── invest/               # Investment dashboard
│   │   └── page.tsx
│   ├── dashboard/            # User dashboard
│   │   └── page.tsx
│   ├── flight-status/        # Flight monitoring
│   │   └── page.tsx
│   └── globals.css           # Global styles
├── components/               # Reusable components
│   ├── ui/                   # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   └── ...
│   ├── layout/               # Layout components
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Navigation.tsx
│   ├── insurance/            # Insurance-specific components
│   │   ├── InsuranceForm.tsx
│   │   ├── PolicyCard.tsx
│   │   └── ClaimStatus.tsx
│   ├── investment/           # Investment components
│   │   ├── VaultCard.tsx
│   │   ├── PortfolioChart.tsx
│   │   └── DepositForm.tsx
│   └── common/               # Common components
│       ├── WalletConnect.tsx
│       ├── LoadingSpinner.tsx
│       └── ErrorBoundary.tsx
├── lib/                      # Utility libraries
│   ├── utils.ts              # General utilities
│   ├── constants.ts          # Application constants
│   ├── web3.ts               # Web3 configuration
│   ├── contracts.ts          # Contract ABIs and addresses
│   └── api.ts                # API utilities
├── hooks/                    # Custom React hooks
│   ├── useWallet.ts          # Wallet connection hook
│   ├── useInsurance.ts       # Insurance contract interactions
│   ├── useVault.ts           # Vault contract interactions
│   └── useFlightStatus.ts    # Flight status monitoring
├── types/                    # TypeScript definitions
│   ├── insurance.ts          # Insurance-related types
│   ├── vault.ts              # Vault-related types
│   ├── flight.ts             # Flight-related types
│   └── web3.ts               # Web3-related types
└── styles/                   # Styling
    └── globals.css           # Global CSS
```

### Smart Contracts Structure (`contracts/`)
```
contracts/
├── interfaces/               # Contract interfaces
│   ├── IERC4626.sol         # ERC4626 vault interface
│   ├── IFlightInsurance.sol # Flight insurance interface
│   └── IOracle.sol          # Oracle interface
├── core/                     # Core contracts
│   ├── FlightInsurance.sol  # Main insurance controller
│   ├── RiskVault.sol        # ERC4626 risk vault
│   └── HedgeVault.sol       # Per-flight hedge vault
├── libraries/                # Contract libraries
│   ├── FlightUtils.sol      # Flight-related utilities
│   ├── Math.sol             # Mathematical operations
│   └── AccessControl.sol    # Access control utilities
├── mocks/                    # Mock contracts for testing
│   ├── MockUSDC.sol         # Mock USDC token
│   ├── MockOracle.sol       # Mock flight oracle
│   └── MockFlightData.sol   # Mock flight data
└── upgradeable/              # Upgradeable contracts (if needed)
    └── Proxy.sol            # Proxy contract
```

### Testing Structure (`test/`)
```
test/
├── unit/                     # Unit tests
│   ├── FlightInsurance.t.sol
│   ├── RiskVault.t.sol
│   └── HedgeVault.t.sol
├── integration/              # Integration tests
│   ├── InsuranceFlow.t.sol
│   ├── VaultOperations.t.sol
│   └── CrossChain.t.sol
├── e2e/                      # End-to-end tests
│   └── FullFlow.t.sol
└── fixtures/                 # Test data and fixtures
    ├── FlightData.json
    └── UserData.json
```

### Scripts Structure (`scripts/`)
```
scripts/
├── deploy/                   # Deployment scripts
│   ├── deploy-base.ts        # Base network deployment
│   ├── deploy-arbitrum.ts    # Arbitrum network deployment
│   └── deploy-crosschain.ts  # Cross-chain deployment
├── utils/                    # Utility scripts
│   ├── verify-contracts.ts   # Contract verification
│   ├── setup-oracles.ts      # Oracle setup
│   └── configure-vaults.ts   # Vault configuration
└── maintenance/              # Maintenance scripts
    ├── update-oracles.ts     # Oracle updates
    └── emergency-pause.ts    # Emergency functions
```

### Documentation Structure (`docs/`)
```
docs/
├── Implementation.md         # Main implementation plan
├── project_structure.md      # This file
├── UI_UX_doc.md             # UI/UX specifications
├── Bug_tracking.md          # Bug tracking and solutions
├── api/                     # API documentation
│   ├── contracts.md         # Smart contract API
│   └── frontend.md          # Frontend API
├── deployment/              # Deployment guides
│   ├── local.md             # Local development
│   ├── testnet.md           # Testnet deployment
│   └── mainnet.md           # Mainnet deployment
└── user-guides/             # User documentation
    ├── insurance-buying.md  # How to buy insurance
    ├── investing.md         # How to invest
    └── claiming.md          # How to claim
```

### Configuration Files
- **`foundry.toml`** - Foundry configuration with compiler settings, test settings, and network configurations
- **`package.json`** - Frontend dependencies, scripts, and project metadata
- **`tailwind.config.js`** - Tailwind CSS configuration with custom theme and plugins
- **`tsconfig.json`** - TypeScript configuration with strict settings and path mappings
- **`.env.example`** - Template for environment variables
- **`.gitignore`** - Git ignore patterns for Node.js, Foundry, and IDE files

### Asset Organization
```
public/
├── images/                   # Static images
│   ├── logo.svg             # Project logo
│   ├── icons/               # Icon assets
│   └── backgrounds/         # Background images
├── fonts/                   # Custom fonts (if any)
└── favicon.ico             # Favicon
```

### Environment Configuration
- **Development**: Local hardhat network with mock contracts
- **Staging**: Base testnet with test contracts
- **Production**: Base and Arbitrum mainnet with production contracts

### Build and Deployment Structure
- **Frontend**: Next.js build system with Vercel deployment
- **Smart Contracts**: Foundry build system with multi-network deployment
- **CI/CD**: GitHub Actions for automated testing and deployment
- **Monitoring**: Contract monitoring and alerting systems

### Security Considerations
- **Access Control**: Role-based access control for admin functions
- **Upgradeability**: Proxy pattern for contract upgrades
- **Auditing**: Regular security audits and code reviews
- **Emergency Functions**: Pause and emergency withdrawal mechanisms 