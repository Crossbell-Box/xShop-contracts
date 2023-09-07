
## Crossbell xShop contracts

[![Docs](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/docs.yml/badge.svg)](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/docs.yml)
[![lint](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/lint.yml/badge.svg)](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/lint.yml)
[![tests](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/tests.yml)
[![checks](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/checks.yml/badge.svg)](https://github.com/Crossbell-Box/crossbell-marketplace-contracts/actions/workflows/checks.yml)
[![codecov](https://codecov.io/gh/Crossbell-Box/crossbell-marketplace-contracts/branch/main/graph/badge.svg?token=J5DF81HHEX)](https://codecov.io/gh/Crossbell-Box/crossbell-marketplace-contracts)
[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/e7178a58-97ab-4362-a5ab-2caa3fbd3a64/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)


## ⚙ Development

Install foundry if you don't have one:
```shell
# install foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Compile and run tests:
```shell
yarn
yarn test
```


**Deploy**
```shell
forge script scripts/Deploy.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --legacy --rpc-url $RPC_URL --ffi                   
forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key $PRIVATE_KEY --broadcast --legacy --rpc-url $RPC_URL --ffi
```

