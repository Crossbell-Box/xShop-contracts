# crossbell config info
crossbell rpc url: https://rpc.crossbell.io

# rinkeby rpc url:
https://eth-rinkeby.alchemyapi.io/v2/7Fg57KefoWIvDxCVLMEKwYgLvuXZ43rH

# mainnet rpc url:
https://eth-mainnet.alchemyapi.io/v2/qY5fX9JGza4Id2YX_PuwBl74hvN-3v_8

# private key 
0xB9A46005d1313cd987631c4DA5C18F9EAc266562

154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42

# forge create 
forge create --rpc-url "https://eth-rinkeby.alchemyapi.io/v2/7Fg57KefoWIvDxCVLMEKwYgLvuXZ43rH" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"

forge create --rpc-url "http://localhost:8545" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"

forge create --rpc-url "http://127.0.0.1:8545/" --private-key 154d74d6e540cd321709630efa94aa264a523b3b6ad792b601602bffe0dcea42 /Users/foooox/template/src/Greeter.sol:Greeter --constructor-args "aa"