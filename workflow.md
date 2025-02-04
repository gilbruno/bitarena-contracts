# Description du workflow pour jouer à un challenge

Lorsque les smart contracts sont déployés; il faut respecter les étapes suivantes pour jouer à un challenge.


## Création d'une platefome de jeux

```shell
make setPlatform PLATFORM_NAME="Platform Name"
```

## Création d'un jeu

```shell
make setGame GAME_NAME="Game Name"
```

## Autorisation de la factory à ineteragir avec le smart contract _BitarenaChallengeData_


```shell
make authorize-contract
```

## Création d'un challenge

```shell
make intentChallengeDeploymentWithForge GAME="FarCry" PLATFORM="Steam" NB_TEAMS=2 NB_PLAYERS=1 AMOUNT=0.01 START_DATE="2025-02-04 15:30:00" IS_PRIVATE=true
```


## Jouer à un challenge

