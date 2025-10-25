# SkyVenture - Aerial Navigation & Pilot Achievement Platform

[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-5546FF)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-6B50FF)](https://www.stacks.co/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

SkyVenture is a decentralized platform built on the Stacks blockchain that empowers the aerial pilot community through airspace mapping, expedition tracking, and achievement-based rewards. The platform creates a trustless, transparent ecosystem where pilots can discover new airspaces, log their expeditions, share community feedback, and earn SkyVenture Aviator Tokens (SVT) for their contributions.

## Features

### 🗺️ Airspace Registry
- **Decentralized Mapping**: Register and discover aerial navigation zones with detailed metadata
- **Comprehensive Details**: Location names, coordinates, altitude limits, terrain types, and regulatory information
- **Community Ratings**: Aggregate scoring system based on pilot feedback
- **Discovery Rewards**: Earn 2.7 SVT for each new airspace registered

### ✈️ Expedition Tracking
- **Detailed Logging**: Record flight duration, altitude, weather conditions, and mission purpose
- **Safety Tracking**: Mark expeditions as successful or unsuccessful
- **Performance Metrics**: Automatic calculation of total airtime and expedition counts
- **Completion Incentives**: Earn 2.3 SVT for successful expeditions, 0.575 SVT for incomplete ones

### 👥 Aviator Profiles
- **Identity Management**: Customizable handles and craft categories
- **Progress Tracking**: Monitor expeditions completed, airspaces discovered, and flight hours
- **Rank System**: Dynamic ranking based on activity and experience (1-5 scale)
- **Achievement System**: Unlock milestones and earn bonus rewards

### 📝 Community Feedback
- **Airspace Reviews**: Rate locations from 1-10 with detailed feedback
- **Safety Assessments**: Categorize airspaces as excellent, good, fair, or risky
- **Endorsement System**: Vote on helpful reviews from other pilots
- **Transparent Reputation**: All feedback permanently recorded on-chain

### 🏆 Achievement System
- **Milestone Tracking**: Unlock achievements based on activity thresholds
- **Bonus Rewards**: Earn 9.8 SVT for each achievement unlocked
- **Built-in Achievements**:
  - `pilot-60`: Complete 60 expeditions
  - `explorer-11`: Discover 11 airspaces
- **Extensible Framework**: Easy to add new achievement types

## Token Economics

### SkyVenture Aviator Token (SVT)

- **Token Symbol**: SVT
- **Decimals**: 6
- **Max Supply**: 35,000 SVT
- **Distribution**:
  - Expedition completion: 2.3 SVT (full), 0.575 SVT (partial)
  - Airspace registration: 2.7 SVT
  - Achievement unlock: 9.8 SVT

### Incentive Structure

The token distribution is designed to reward active participation and quality contributions:

1. **Expedition Rewards**: Encourage regular platform usage and accurate logging
2. **Discovery Rewards**: Incentivize expansion of the airspace database
3. **Achievement Bonuses**: Recognize long-term commitment and expertise

## Smart Contract Architecture

### Data Structures

#### Aviator Registry
```clarity
{
  handle: (string-ascii 24),
  craft-category: (string-ascii 12),
  expeditions-completed: uint,
  airspaces-discovered: uint,
  airtime-hours: uint,
  aviator-rank: uint,
  registration-block: uint
}
```

#### Airspace Registry
```clarity
{
  location-name: (string-ascii 30),
  geo-coordinates: (string-ascii 24),
  airspace-category: (string-ascii 12),
  ceiling-meters: uint,
  landscape: (string-ascii 12),
  regulatory-notes: (string-ascii 20),
  registered-by: principal,
  expedition-tally: uint,
  community-score: uint
}
```

#### Expedition Ledger
```clarity
{
  airspace-ref: uint,
  aviator: principal,
  duration-minutes: uint,
  peak-altitude: uint,
  atmospheric-state: (string-ascii 8),
  expedition-purpose: (string-ascii 12),
  expedition-memo: (string-ascii 100),
  expedition-block: uint,
  completed-safely: bool
}
```

## Usage Guide

### Registering an Airspace

```clarity
(contract-call? .skyventure register-airspace
  "Mountain Ridge Vista"
  "40.7128,-74.0060"
  "recreational"
  u400
  "mountain"
  "daylight only"
)
```

### Recording an Expedition

```clarity
(contract-call? .skyventure record-expedition
  u1                    ;; airspace-ref
  u45                   ;; duration-minutes
  u350                  ;; peak-altitude
  "clear"               ;; atmospheric-state
  "photography"         ;; expedition-purpose
  "Captured sunrise footage"  ;; expedition-memo
  true                  ;; completed-safely
)
```

### Submitting Feedback

```clarity
(contract-call? .skyventure submit-feedback
  u1                    ;; airspace-ref
  u9                    ;; score (1-10)
  "Excellent views, clear approach paths, minimal obstructions"
  "excellent"           ;; safety-assessment
)
```

### Unlocking Achievements

```clarity
(contract-call? .skyventure unlock-achievement "pilot-60")
```

### Updating Profile

```clarity
(contract-call? .skyventure update-handle "SkyMaverick")
(contract-call? .skyventure update-craft-category "racing")
```

## Read-Only Functions

Query contract state without making transactions:

```clarity
;; Get aviator profile
(contract-call? .skyventure get-aviator-profile 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get airspace details
(contract-call? .skyventure get-airspace-details u1)

;; Get expedition record
(contract-call? .skyventure get-expedition-record u1)

;; Get feedback
(contract-call? .skyventure get-airspace-feedback u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get achievement status
(contract-call? .skyventure get-achievement-status 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "pilot-60")

;; Check token balance
(contract-call? .skyventure get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.0.0 or higher
- [Node.js](https://nodejs.org/) v16+ (for tooling)
- [Stacks CLI](https://docs.stacks.co/docs/cli) (optional)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/skyventure.git
cd skyventure
```

2. Install Clarinet:
```bash
# macOS
brew install clarinet

# Linux/Windows
# Follow instructions at https://github.com/hirosystems/clarinet
```

3. Check installation:
```bash
clarinet --version
```

### Testing

Run the test suite:

```bash
clarinet test
```

Run specific test files:

```bash
clarinet test tests/skyventure_test.ts
```

### Deployment

1. Configure your deployment settings in `Clarinet.toml`

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Considerations

### Access Control
- Contract admin is immutable (set to deployer)
- Only aviators can submit feedback for airspaces they haven't reviewed
- Achievements can only be unlocked once per aviator

### Input Validation
- All string inputs are validated for non-zero length
- Numeric inputs are range-checked (e.g., ratings 1-10)
- Altitude limits are enforced during expedition recording
- Token minting respects maximum supply constraints

### Data Integrity
- Duplicate prevention on reviews and achievements
- Immutable expedition and airspace records
- Transparent token distribution tracking

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| u100 | `err-admin-only` | Operation requires contract admin privileges |
| u101 | `err-record-not-found` | Requested record does not exist |
| u102 | `err-duplicate-entry` | Entry already exists (reviews, achievements) |
| u103 | `err-access-denied` | Unauthorized operation attempt |
| u104 | `err-invalid-parameter` | Invalid input parameter provided |

## Roadmap

### Phase 1 (Current)
- ✅ Core airspace and expedition functionality
- ✅ Token incentive system
- ✅ Basic achievement framework
- ✅ Community feedback system

### Phase 2 (Q2 2025)
- [ ] Advanced achievement types
- [ ] Aviator-to-aviator token transfers
- [ ] Airspace ownership transfers
- [ ] Enhanced ranking algorithms

### Phase 3 (Q3 2025)
- [ ] Mobile app integration
- [ ] Real-time expedition tracking
- [ ] Weather API integration
- [ ] Social features and pilot networking

### Phase 4 (Q4 2025)
- [ ] DAO governance implementation
- [ ] Community treasury management
- [ ] NFT badges for achievements
- [ ] Cross-chain bridge exploration

## Contributing

We welcome contributions from the community! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [docs.skyventure.io](https://docs.skyventure.io)
- **Discord**: [discord.gg/skyventure](https://discord.gg/skyventure)
- **Twitter**: [@SkyVenture](https://twitter.com/skyventure)
- **Email**: support@skyventure.io

## Acknowledgments

- Built on [Stacks](https://www.stacks.co/) blockchain
- Powered by [Clarity](https://clarity-lang.org/) smart contracts
- Community-driven development

---

**Disclaimer**: This platform is for informational and community purposes. Always follow local aviation regulations and safety guidelines. SkyVenture does not provide flight authorization or replace official aviation systems.
