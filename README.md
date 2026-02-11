# APEX-Contract

## Quick Start

Setup Foundry
```
curl -L https://foundry.paradigm.xyz | bash
foundryup
cd contracts
forge install foundry-rs/forge-std
```

Setup Environmental Variables
```
BASE_SEPOLIA_RPC_URL=
PRIVATE_KEY=
BASESCAN_API_KEY=
```

```
set -a
source .env
set +a
```

Deploy the contracts

```
cd contracts

forge build

forge script script/Deploy.s.sol \
  --rpc-url base_sepolia \
  --broadcast \
  --verify
```

