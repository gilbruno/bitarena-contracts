# Factory Smart Contract

When we'll deploy the Factory smart contract, we'll set in the constructor an address for admin of all challenges and an address for all admin of challenge disputes.
These addresses can be set later for each challenges


## intentChallengeDeployment

### Description
If a creator wants to create a challenge he must call this function

### parameters

 - string _game : name of the Game (Ex: Apex)
 - string _platform : name of the Game (Ex: Steam)
 - uint16 _nbTeams : number of teams per challenge 
 - uint16 _nbTeamPlayers : number of players per team
 - uint256 _amountPerPlayer : Amount each of players must pay to join a team
 - uint256 _startAt : Timestamp expressed in seconds for the start of the challenge
 - bool _isPrivate : indicate if the challenge is private or not


## getChallengeCounter

### Description
Returns the count of challenges created

### parameters

none

## getChallengeByIndex

### Description
Returns the _Challenge_ object of the matching index.
The signature of the _Challenge_ object is 

```
struct Challenge {
    address challengeCreator;
    address challengeAddress;
    string game;
    string platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint amountPerPlayer;
    uint startAt;
    bool isPrivate;
}   
```

### parameters

 - uint256 index : The index of the challange

## getChallengesArray

### Description
Returns the array of _Challenge_ objects

### parameters

None


## isChallengeDeployed

### Description
Returns _true_ if the challenge with index _index_ is deployed or not

### parameters

 - uint256 index



# Challenge Smart Contract

## createOrJoinTeam

### Description

This function must be call by anyone who wants to join an existing team or create a team.

### parameters

 - uint256 index : Must take the value _0_ to create a team or different from _0_ to join a team by its index

## cancelChallenge

### Description 

This function is callable only by the creator og the challenge.
An error will be thrown if it's not the case

### parameters

none

## claimVictory

### Description 

This function is callable by one of the player of the challenge to claim the victory for the current challenge

### parameters

none

## participateToDispute

### Description 

This function is callable by one of the player of the challenge to participate to a challenge duspute in case of at least 2 teams claimed the victory

### parameters

none

## revealWinnerAfterDispute

### Description 

This function is callable only by the admin of the dispute challenge. Throw an error if it's not the case.
If at least 2 teams particpated to a dispute, this function reveals the real winner of the challenge

### parameters

 - uint16 _teamIndex : index of the team in the challenge

## calculateFeeAmount

### Description 

This function calculates the fee amount for the current challenge

### parameters

none

## calculatePoolAmountToSendBackForWinnerTeam

### Description 

This function calculates the total amount that the winner team can withdraw after the winner was revealed or not

### parameters

none

## withdrawChallengePool

### Description 

This function is callable only by the real winner of the challenge and it dispatches this won amount to each team participant. It give back amount disputye participation to the address that participated to the dispute

### parameters

none

## getIsCanceled

### Description 

Returns true if the challenge was canceled by its creator.
False otherwise.

### parameters

none

## getIsPoolWithdrawed

### Description 

Returns true if the pool challenge was withdrawed by a winner team member
False otherwise.

### parameters

none

## getTeamOfPlayer

### Description 

Returns the team index of the address as parameter

### parameters

 - address _player

## getTeamOfPlayegetChallengePool

### Description 

Returns the pool amount when the function is called

### parameters

none

## getDisputeAmountParticipation

### Description 

Returns the amount a player must pay to participate to a dispute 

### parameters

none

## getChallengeAdmin

### Description 

Returns the address of the admin of the challenge

### parameters

none

## getDisputeAdmin

### Description 

Returns the address of the admin of dispute of the challenge

### parameters

none

## getDisputeParticipantsCount

### Description 

Returns number of dispute participants 

### parameters

none

## getWinnersClaimedCount

### Description 

Returns the number of teams that claim the victory

### parameters

none


TODO : Setters to write in this doc









