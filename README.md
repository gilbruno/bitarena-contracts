## Introduction

This project aims at building smart contracts for the Bitarena Platform.<br>
You can see the project at : https://bitarena.app

<img src="./img/bitarena.png" alt="Bitarena" title="Optional title">

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


## INTERACT WITH SMART CONTRACT FACTORY

### Challenge intent creation

#### Remarks : 

<b>
This function must be used if trhe process of challenge is divided in 2 transactions.
Tx #1 : The gamer who wants to create a challenge signs a Tx to intent the challenge creation
Tx #2 : The Bitarena protocol signs a second Tx to deploy dynamically the smart contract of the challenge
</b>

<br>

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
cast send $ADDRESS_LAST_DEPLOYED_FACTORY "intentChallengeCreation(bytes32,bytes32,uint16,uint16,uint256,uint256,bool)" 0x67616d6531000000000000000000000000000000000000000000000000000000 0x706c6174666f726d310000000000000000000000000000000000000000000000 2 2 10000000000000000 1727102520 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY_ADMIN_FACTORY --legacy --value 10000000000000000
```


In order to work this tx must respect implemented rules. See the code for revert errors.

This method is working if you decide to have _game_ and _platform_ as _byte32_ type.<br>
If you decide to have these fields as _string_ type, the command is : <br>

```shell
cast send $ADDRESS_LAST_DEPLOYED_FACTORY "intentChallengeCreation(string,string,uint16,uint16,uint256,uint256,bool)" "Counter Strike" "Steam" 2 2 10000000000000000 1727254236 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY_ADMIN_FACTORY --legacy --value 10000000000000000
```


The <factory_address> is given by the script that deploys the factory (_make deployFactory_)

### Challenge intent deployment

This version is used if the process of challenge deployment is done by a single transaction where the gamer who wants to create a challenge is in charge to supporrt fees for the smart contract deployment of the challenge

```shell
cast send $ADDRESS_LAST_DEPLOYED_FACTORY "intentChallengeDeployment(bytes32,bytes32,uint16,uint16,uint256,uint256,bool)" 0x67616d6531000000000000000000000000000000000000000000000000000000 0x706c6174666f726d310000000000000000000000000000000000000000000000 2 2 10000000000000000 1727102520 true --rpc-url $RPC_URL --private-key $PRIVATE_KEY_ADMIN_FACTORY --legacy --value 10000000000000000
```


## Set Games

Transaction to set games on the blockchain

```
make setGame GAME_NAME="Counter Strike"
```

## Get Games

To see the Hex value of the game by providing the index of games array

```
make getGame GAME_INDEX=0
```

the terminal returns a hex value.
To decode it, you can run the followingcommand

## Decode Hex value

```
make decode HEX_VALUE=0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000e436f756e74657220537472696b65000000000000000000000000000000000000
```

This returns : <br>

```
Counter Strike
```

## Set Platforms

Transaction to set platforms on the blockchain

```
make setPlatform PLATFORM_NAME="steam"
```

## Get Platforms

To see the Hex value of the game by providing the index of platforms array

```
make getPlatform PLATFORM_INDEX=0
```

the terminal returns a hex value.
To decode it, you can run the command to decode hex value


# Deploy all contracts with Catapulta (Factory & Games)


```sh
catapulta script script/catapulta/Deploy.s.sol:DeployScript --network amoy --legacy --sender 0xdB70Ce51809af94EC2d4CC2dc2fD1f099A7cDE0C
```

## Last deployment on Ploygon Amoy 

```sh
BitarenaGames deployed to 0x7BE9EA5CF0C5d1ECbe5a381CffC0D1AF6dbdEA69
BitarenaFactory implementation deployed to 0xE841360c051D040C9447A667aAA9aF15EC8fF26F
https://catapulta.sh/project/678f558bf2e1970d286019ed/op/40625bcf-ba6d-4d15-bf52-9815db15c35a
```

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

