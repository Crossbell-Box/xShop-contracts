# how to use:

**Setup**
```bash
make
# OR #
make setup
```

**Building**
```bash
make build
```

**Testing**
```bash
make test
```

**Deploy & Verify**
```bash
yarn
deploy_XXX.sh
```
(It works fine with rinkeby but fails on deploy_local.sh...
deploy_local.sh forks ethereum mainnet at a defined block height and start node locally.
My local node works fine, but I can't use forge create to depoly contract to it...
/todo/
)

# crossbell config info
crossbell rpc url: https://rpc.crossbell.io

# rinkeby rpc url:
https://eth-rinkeby.alchemyapi.io/v2/7Fg57KefoWIvDxCVLMEKwYgLvuXZ43rH

# mainnet rpc url:
https://eth-mainnet.alchemyapi.io/v2/qY5fX9JGza4Id2YX_PuwBl74hvN-3v_8

# private key 
154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42

# forge create 
forge create --rpc-url "https://eth-rinkeby.alchemyapi.io/v2/7Fg57KefoWIvDxCVLMEKwYgLvuXZ43rH" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"

forge create --rpc-url "http://localhost:8545" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"

forge create --rpc-url "http://127.0.0.1:8545/" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"

forge create --rpc-url "http://127.0.0.1:8545/" --private-key df57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"