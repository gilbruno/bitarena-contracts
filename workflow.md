# Description du workflow pour jouer à un challenge

Lorsque les smart contracts sont déployés, il faut respecter les étapes suivantes pour jouer à un challenge.
Attention à bien paramétrer les vars nécessaires dans le fichier .env (rpc url, pk, sk, etc...)


## Création d'un mode de jeu

```shell
make setMode NB_TEAMS=2 NB_PLAYERS=1
make setMode NB_TEAMS=2 NB_PLAYERS=2
```

## Création d'une platefome de jeux

```shell
make setPlatform PLATFORM_NAME="Platform Name"
```

## Création d'un jeu

```shell
make setGame GAME_NAME="Game Name"
```

## Autorisation de la factory à interagir avec le smart contract _BitarenaChallengeData_


```shell
make authorize-contract
```

## Création d'un challenge

```shell
make intentChallengeDeploymentWithForge GAME="Farcry" PLATFORM="Steam" NB_TEAMS=2 NB_PLAYERS=1 AMOUNT=0.01 START_DATE="2025-02-04 15:30:00" IS_PRIVATE=true
```

A la suite de cette commande, le challenge est créé, une team a été créé et le createur du challenge fait partie de la team 1.

## Jouer à un challenge

Si TEAM_INDEX vaut 0, alors c'est une nouvelle équipe qui est créée.

```shell
make createOrJoinTeamWithForge CHALLENGE_ADDRESS=0xaB809Fc8011bAc3062699E0586F0F623D848bc2B TEAM_INDEX=0 AMOUNT=0.01
```

## Réclamation de la victoire

```shell
make claimVictoryWithForge CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6
```

Si vous avez une erreur "DelayClaimVictoryNotSet", vous abez surement oublié de configurer le délai de réclamation de la victoire.
Les delai start et end sont configurés par défaut à 1 minute et 1 heure.
Mais si vous avez une valeur nulle, cette erreor est lancé.
Vous devez donc configurer les delais comme par exemple ci-dessous.


```shell
make setDelayVictoryClaim CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6 IS_START_DELAY=true DELAY=1 minutes
make setDelayVictoryClaim CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6 IS_START_DELAY=false DELAY=1 hours
```

Vous pouvez vérifiez les delais avec les commandes suivantes.

```shell
make getDelayStartVictoryClaim CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6
make getDelayEndVictoryClaim CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6
```

Elles doivent vous renvoyer les delais configurés non nulls.

## Retrait du pool

```shell
make withdrawChallengePool CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6
```
Si l'erreur "MustWaitForEndDisputePeriodError" est lancée, c'est que l'application n'a pas attendu la fin de la période de participation à la dispute. L'application doit attendre la fin de la période de participation à la dispute avant de pouvoir retirer le pool. 
Meme s'il n'y a pas de dispute, l'application doit attendre la fin de la période de participation à la dispute avant de pouvoir retirer le pool.

Pour vérifier la date possible de retirer le pool, vous pouvez utiliser la commande suivante.

```shell
make getWithdrawDate CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6
```

Pour configurer le délai de participation à la dispute, vous pouvez utiliser les commandes suivantes.

```shell
make setDelayDisputeParticipation CHALLENGE_ADDRESS=0xDb650ba03DA8E982d25FBEfc973277c758bf38D6 IS_START_DELAY=false DELAY=1 hours
```



