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

A la suite de cette commande, le challenge est créé, une team a été créé et le createur du challenge fait partie de la team 1.

## Jouer à un challenge

Si TEAM_INDEX vaut 0, alors c'est une nouvelle équipe qui est créée.

```shell
make createOrJoinTeamWithForge CHALLENGE_ADDRESS=0xaB809Fc8011bAc3062699E0586F0F623D848bc2B TEAM_INDEX=0 AMOUNT=0.01
```



