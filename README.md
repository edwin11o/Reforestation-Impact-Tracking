# Reforestation Impact Tracking Smart Contract

A Clarity smart contract for monitoring and rewarding tree planting initiatives with verifiable satellite data on the Stacks blockchain.

## Overview

This smart contract enables:
- **Project Creation**: Users can create reforestation projects with target tree counts
- **Satellite Verification**: Authorized verifiers can submit satellite-based tree counting data
- **Automated Rewards**: Verified tree planting efforts are rewarded with STX tokens
- **Impact Tracking**: Comprehensive tracking of global reforestation impact

## Features

### Core Functionality
- ✅ Create reforestation projects with location and target tree counts
- ✅ Multi-verifier satellite data validation system
- ✅ Automated reward distribution for verified plantings
- ✅ Comprehensive project and user statistics tracking
- ✅ Admin controls for reward rates and verification thresholds

### Smart Contract Components
- **Projects**: Track individual reforestation initiatives
- **Verifications**: Store satellite verification data with coordinates and confidence scores
- **Rewards**: Automated STX distribution based on verified tree counts
- **Statistics**: Global and per-user impact metrics

## Contract Architecture

### Data Structures
- `projects`: Main project data with owner, location, targets, and status
- `satellite-verifications`: Verification data from authorized satellite data providers
- `verifiers`: Authorized entities that can submit verification data
- `user-rewards`: Track rewards earned by project creators
- `project-verifications`: Aggregated verification status per project

### Key Functions
- `create-project`: Initialize new reforestation project
- `submit-satellite-verification`: Submit satellite-based tree count data
- `process-verification`: Aggregate verifications and trigger rewards
- `distribute-rewards`: Send STX rewards for verified tree plantings

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Reward Token**: STX
- **Default Reward**: 1 STX per verified tree
- **Verification Threshold**: 3 independent verifications required
- **Confidence Minimum**: 70% satellite data confidence score

## Usage

### For Project Creators
1. Call `create-project` with location and target tree count
2. Plant trees in the specified location
3. Wait for satellite verification from authorized verifiers
4. Receive automatic STX rewards upon verification

### For Verifiers
1. Get authorized by contract admin via `add-verifier`
2. Submit verification data using `submit-satellite-verification`
3. Include coordinates, tree count, and confidence score
4. Build reputation through accurate verifications

### For Administrators
1. Add/manage authorized verifiers
2. Adjust reward rates with `set-reward-per-tree`
3. Modify verification thresholds
4. Fund contract for reward distribution

## Installation & Deployment

### Prerequisites
- Clarinet CLI installed
- Stacks wallet configured
- Node.js and TypeScript (for testing)

### Local Development
```bash
# Clone the repository
git clone https://github.com/edwin11o/Reforestation-Impact-Tracking.git
cd Reforestation-Impact-Tracking

# Run contract checks
clarinet check

# Deploy to local testnet
clarinet integrate
```

### Testing
```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/reforestation_test.ts
```

## API Reference

### Read-Only Functions
- `get-project(project-id: uint)`: Get project details
- `get-user-rewards(user: principal)`: Get user reward statistics
- `get-total-trees-planted()`: Get global tree count
- `get-verifier-info(verifier: principal)`: Get verifier details

### Public Functions
- `create-project(location, target-trees)`: Create new project
- `submit-satellite-verification(project-id, trees-count, coordinates, confidence-score)`: Submit verification
- `process-verification(project-id)`: Process and aggregate verifications
- `fund-contract(amount)`: Add STX to contract for rewards

## Environmental Impact

This smart contract directly supports:
-  **Reforestation Initiatives**: Incentivizing tree planting worldwide
-  **Data Transparency**: Satellite verification ensures accurate reporting
-  **Economic Incentives**: Direct rewards for environmental action
-  **Impact Measurement**: Comprehensive tracking of reforestation success

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

**Developer**: Edwin Onyeka  
**GitHub**: [@edwin11o](https://github.com/edwin11o)  
**Email**: onyekaedwin191@gmail.com

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Satellite data providers for environmental monitoring
- Global reforestation community for inspiration

---

*Building a greener future, one verified tree at a time* 