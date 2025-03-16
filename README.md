# Blockchain-Based Sustainable Fishing Certification

A blockchain-based system for tracking and certifying sustainable fishing practices using Clarity smart contracts on the Stacks blockchain.

## Project Overview

This project implements a decentralized system for tracking the entire fishing supply chain and certifying sustainable practices. The system allows for:

1. Registering and managing fishing vessels and their equipment
2. Documenting fishing trips and catches with location data
3. Tracking the processing and chain of custody of fish products
4. Issuing and verifying sustainability certifications

## Smart Contracts

### Vessel Registration Contract

Records details of fishing boats and equipment:
- Register vessels with detailed information
- Track vessel equipment and certifications
- Manage vessel status and ownership

### Catch Documentation Contract

Tracks species, quantities, and locations:
- Document fishing trips with departure/return information
- Record catches with species, quantity, and location data
- Verify catches by authorized entities

### Processing Verification Contract

Monitors chain of custody to consumer:
- Register processing facilities
- Track processing batches from raw catch to finished product
- Record and verify custody transfers between entities

### Sustainability Certification Contract

Issues verifiable eco-friendly credentials:
- Define sustainability standards and criteria
- Issue certifications to vessels, facilities, or products
- Conduct and record certification audits
- Verify certification status

## Testing

Tests are implemented using Vitest, focusing on unit testing the contract functions without relying on external libraries like @hirosystems/clarinet-sdk or @stacks/transactions.

## Getting Started

1. Clone the repository
2. Install dependencies
3. Run tests with `npm test`

## Development Roadmap

- Phase 1: Core contract implementation and testing
- Phase 2: Integration with IoT devices for automated data collection
- Phase 3: Consumer-facing verification interface
- Phase 4: Integration with existing certification bodies

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

