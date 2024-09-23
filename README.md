## Specific commands for the Bitarena smart contracts

### Deploy Bitarena Factory

```
make deployFactory
```

### See uncovered lines by units tests


```
forge coverage --report debug
```

### GenerateABI

To generate an ABI of a smart contract :

```shell
forge build --silent && jq '.abi' ./out/BitarenaFactory.sol/BitarenaFactory.json > ./abi/BitarenaFactory.json
```


### INTERACT WITH SMART CONTRACT FACTORY

## Challenge intent creation

Reminder : <br>
The function signature is <br>

```
function intentChallengeCreation(bytes32 _game, bytes32 _platform, uint16 _nbTeams, uint16 _nbTeamPlayers, uint256 _amountPerPlayer, uint256 _startAt, bool _isPrivate)
```

So if we want to create a challenge with parameters : 

GAME="game1"<br>
PLATFORM="platform1"<br>
NB_TEAMS=2<br>
NB_TEAM_PLAYERS=2<br>
AMOUNT_PER_PLAYER=10000000000000000 (0.01 ETH = 10^16 wei)<br> 
START_AT=1727089883 (see https://www.epochconverter.com/ to select a timestamp)<br>
IS_PRIVATE=true<br>

you must convert your strings "game1" and "platform1" in byte32 (go to https://www.devoven.com/encoding/string-to-bytes32) <br>
So "game1" is equal to 0x67616d6531
and "platform1" is equal to 0x706c6174666f726d31
<br>
_byte32_ must contain 32 bytes so 64 hex char. It must be filled with n '0' until 64 char.

"game1" is equal to 0x67616d6531000000000000000000000000000000000000000000000000000000
"platform1" is equal to 0x706c6174666f726d310000000000000000000000000000000000000000000000

So the final command line is : <br>


```shell
cast send $ADDRESS_LAST_DEPLOYED_FACTORY "intentChallengeCreation(bytes32,bytes32,uint16,uint16,uint256,uint256,bool)" 0x67616d6531000000000000000000000000000000000000000000000000000000 0x706c6174666f726d310000000000000000000000000000000000000000000000 2 2 10000000000000000 1727102520 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY --legacy --value 10000000000000000
```


In order to work this tx must respect implemented rules. See the code for revert errors.


The <factory_address> is given by the script that deploys the factory (_make deployFactory_)

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

