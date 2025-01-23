-include audit/audit.mk

.PHONY: deploy

# Charger les variables d'environnement à partir du fichier .env
include .env
export $(shell sed 's/=.*//' .env)

deployGames:
	@echo "Deploying the BitarenaGames contract..."
	forge script script/DeployBitarenaGames.s.sol:DeployBitarenaGames --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --broadcast --legacy

deployFactory:
	@echo "Deploying the Bitarena Factory contract..."
	forge script script/DeployBitarenaFactory.s.sol:DeployBitarenaFactory --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_FACTORY) --broadcast --legacy

generateFactoryAbi:
	@echo "Generate Factory ABI"
	forge build --silent && jq '.abi' ./out/BitarenaFactory.sol/BitarenaFactory.json > ./abi/BitarenaFactory.json

generateChallengeAbi:
	@echo "Generate Challenge ABI"
	forge build --silent && jq '.abi' ./out/BitarenaChallenge.sol/BitarenaChallenge.json > ./abi/BitarenaChallenge.json

generateChallengesDataAbi:
	@echo "Generate ChallengesData ABI"
	forge build --silent && jq '.abi' ./out/BitarenaChallengesData.sol/BitarenaChallengesData.json > ./abi/BitarenaChallengesData.json
	
generateBitarenaGamesAbi:
	@echo "Generate BitarenaGames ABI"
	forge build --silent && jq '.abi' ./out/BitarenaGames.sol/BitarenaGames.json > ./abi/BitarenaGames.json

setGame:
	@if [ -z "$(GAME_NAME)" ]; then \
        echo "Usage: make setGame GAME_NAME=<value>"; \
        exit 1; \
    fi
	cast send $(ADDRESS_LAST_DEPLOYED_GAMES) "setGame(string)" "$(GAME_NAME)" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --gas-price 50000000000 --legacy

setPlatform:
	@if [ -z "$(PLATFORM_NAME)" ]; then \
        echo "Usage: make setPlatform PLATFORM_NAME=<value>"; \
        exit 1; \
    fi
	cast send $(ADDRESS_LAST_DEPLOYED_GAMES) "setPlatform(string)" "$(PLATFORM_NAME)" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --legacy

estimateGasCost:
	@if [ -z "$(GAME_NAME)" ]; then \
		echo "Usage: make estimateGasCost GAME_NAME=<value>"; \
		exit 1; \
	fi
	@echo "Estimating total cost for setGame with game name: $(GAME_NAME)"
	@echo "Gas Price: 50 gwei"
	@GAS=$$(cast estimate $(ADDRESS_LAST_DEPLOYED_GAMES) \
		"setGame(string)" \
		"$(GAME_NAME)" \
		--from $(PUBLIC_KEY_ADMIN_GAMES) \
		--rpc-url $(RPC_URL)) && \
	TOTAL_WEI=$$(($$GAS * 50000000000)) && \
	echo "Estimated gas units: $$GAS" && \
	echo "Total cost in wei: $$TOTAL_WEI" && \
	cast --to-unit $$TOTAL_WEI

checkBalance:
	@if [ -z "$(PUBLIC_KEY)" ]; then \
		echo "Usage: make checkBalance PUBLIC_KEY=<address>"; \
		exit 1; \
	fi
	@echo "Checking balance for address $(PUBLIC_KEY)..."
	cast balance $(PUBLIC_KEY) --rpc-url "https://rpc.sepolia.org"

getGame:
	@if [ -z "$(GAME_INDEX)" ]; then \
        echo "Usage: make getGame ARG=<value>"; \
        exit 1; \
    fi
	cast call $(ADDRESS_LAST_DEPLOYED_GAMES) "getGameByIndex(uint256)" $(GAME_INDEX) --rpc-url $(RPC_URL) --legacy	

# Returns all games playable by the contract BitarenaGames 
# call ex :
# make getGames BITARENA_GAMES_ADDRESS=0x123...
getGames:
	@if [ -z "$(BITARENA_GAMES_ADDRESS)" ]; then \
		echo "Usage: make getGames BITARENA_GAMES_ADDRESS=<address>"; \
		exit 1; \
	fi
	cast call $(BITARENA_GAMES_ADDRESS) \
	"getGames()(string[])" \
	--rpc-url $(RPC_URL) \
	--legacy	

getPlatform:
	@if [ -z "$(PLATFORM_INDEX)" ]; then \
        echo "Usage: make getPlatform ARG=<value>"; \
        exit 1; \
    fi
	cast call $(ADDRESS_LAST_DEPLOYED_GAMES) "getPlatformByIndex(uint256)" $(PLATFORM_INDEX) --rpc-url $(RPC_URL) --legacy	

decode:
	@if [ -z "$(HEX_VALUE)" ]; then \
		echo "Usage: make decode HEX_VALUE=<hex_value>"; \
	exit 1; \
	fi
	python3 decode_hex.py $(HEX_VALUE)

intentChallengeCreation:
	@echo "Intent challenge creation ...."
	cast send $(ADDRESS_LAST_DEPLOYED_FACTORY) "intentChallengeCreation(string,string,uint16,uint16,uint256,uint256,bool)" "Counter Strike" "Steam" 2 2 10000000000000000 1727268662 true --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_CREATOR_CHALLENGE) --legacy --value 10000000000000000

deployChallenge:
	@if [ -z "$(CHALLENGE_INDEX)" ]; then \
		echo "Usage: make deployChallenge ARG=<value>"; \
		exit 1; \
	fi
	@echo "Challenge Deployment of challenge with index ...."
	cast send $(ADDRESS_LAST_DEPLOYED_FACTORY) "createChallenge(address,address,uint256)" $(PUBLIC_KEY_ADMIN_CHALLENGE) $(PUBLIC_KEY_ADMIN_DISPUTE_CHALLENGE) $(CHALLENGE_INDEX) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_FACTORY) --legacy --json

intentChallengeDeployment:
	@if [ -z "$(FACTORY_ADDRESS)" ] || [ -z "$(GAME)" ] || [ -z "$(PLATFORM)" ] || [ -z "$(NB_TEAMS)" ] || [ -z "$(NB_PLAYERS)" ] || [ -z "$(AMOUNT)" ] || [ -z "$(START_TIME)" ] || [ -z "$(IS_PRIVATE)" ]; then \
		echo "Usage: make intentChallengeDeployment FACTORY_ADDRESS=<address> GAME=<game> PLATFORM=<platform> NB_TEAMS=<teams> NB_PLAYERS=<players> AMOUNT=<amount> START_TIME=<time> IS_PRIVATE=<bool>"; \
		exit 1; \
	fi
	cast send $(FACTORY_ADDRESS) \
	"intentChallengeDeployment(string,string,uint16,uint16,uint256,uint256,bool)" \
	"$(GAME)" \
	"$(PLATFORM)" \
	$(NB_TEAMS) \
	$(NB_PLAYERS) \
	$$(cast --to-wei $(AMOUNT) eth) \
	$$(date -d "$(START_TIME)" +%s) \
	$(IS_PRIVATE) \
	--value $$(cast --to-wei $(AMOUNT) eth) \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY_CREATOR_CHALLENGE) \
	--legacy \

debugIntentChallengeDeployment:
	@if [ -z "$(FACTORY_ADDRESS)" ] || [ -z "$(GAME)" ] || [ -z "$(PLATFORM)" ] || [ -z "$(NB_TEAMS)" ] || [ -z "$(NB_PLAYERS)" ] || [ -z "$(AMOUNT)" ] || [ -z "$(START_TIME)" ] || [ -z "$(IS_PRIVATE)" ]; then \
		echo "Usage: make intentChallengeDeployment FACTORY_ADDRESS=<address> GAME=<game> PLATFORM=<platform> NB_TEAMS=<teams> NB_PLAYERS=<players> AMOUNT=<amount> START_TIME=<time> IS_PRIVATE=<bool>"; \
		exit 1; \
	fi
	cast call $(FACTORY_ADDRESS) \
	"intentChallengeDeployment(string,string,uint16,uint16,uint256,uint256,bool)" \
	"$(GAME)" \
	"$(PLATFORM)" \
	$(NB_TEAMS) \
	$(NB_PLAYERS) \
	$$(cast --to-wei $(AMOUNT) eth) \
	$$(date -d "$(START_TIME)" +%s) \
	$(IS_PRIVATE) \
	--value $$(cast --to-wei $(AMOUNT) eth) \
	--rpc-url $(RPC_URL) \
	--from $(PUBLIC_KEY_CREATOR_CHALLENGE) \
	--legacy \
	--trace
	
# Ajouter cette nouvelle commande dans votre Makefile
debug-intent:
	@echo "Simulation de intentChallengeCreation pour debug..."
	cast call $(ADDRESS_LAST_DEPLOYED_FACTORY) \
	"intentChallengeCreation(string,string,uint16,uint16,uint256,uint256,bool)" \
	"FarCry" \
	"Steam" \
	2 \
	2 \
	10000000000000000 \
	1727268662 \
	true \
	--rpc-url $(RPC_URL) \
	--from $(PUBLIC_KEY_CREATOR_CHALLENGE)

getFactoryChallengeCounter:
	@echo "Get Factory Challenge Counter ...."
	cast call $(ADDRESS_LAST_DEPLOYED_FACTORY) "getChallengeCounter()" --rpc-url $(RPC_URL) --legacy	

# Add X minutes to claim victory
# To call it: make setDelayStartForVictoryClaim CHALLENGE_ADDRESS=0x2eb1.... MINUTES=20 
# to add only20minutes instead of 1 hour
setDelayStartForVictoryClaim:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(MINUTES)" ]; then \
		echo "Usage: make setDelayStartForVictoryClaim CHALLENGE_ADDRESS=<challenge_address> MINUTES=<number_of_minutes>"; \
		exit 1; \
	fi
	cast send $(CHALLENGE_ADDRESS) "setDelayStartForVictoryClaim(uint256)" $(shell expr $(MINUTES) \* 60) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_FACTORY) --legacy

getDelayStartVictoryClaim:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getDelayStartVictoryClaim CHALLENGE_ADDRESS=<challenge_adddress>"; \
		exit 1; \
	fi
	@echo "Get Delay start victory claim ...."
	cast call $(CHALLENGE_ADDRESS) "getDelayStartVictoryClaim()" --rpc-url $(RPC_URL) --legacy	


getChallengeAdmin:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getChallengeAdmin CHALLENGE_ADDRESS=<challenge_address>"; \
		exit 1; \
	fi
	@echo "Get Challenge Admin ...."
	cast call $(CHALLENGE_ADDRESS) "getChallengeAdmin()" --rpc-url $(RPC_URL) --legacy

getChallengeByIndex:
	@if [ -z "$(FACTORY_ADDRESS)" ] || [ -z "$(CHALLENGE_INDEX)" ]; then \
		echo "Usage: make getChallengeByIndex FACTORY_ADDRESS=<factory_address> CHALLENGE_INDEX=<index>"; \
		exit 1; \
	fi
	@echo "Get Challenge at index $(CHALLENGE_INDEX) from factory $(FACTORY_ADDRESS)...."
	cast call $(FACTORY_ADDRESS) "getChallengeByIndex(uint256)" $(CHALLENGE_INDEX) --rpc-url $(RPC_URL) --legacy

getChallengesArray:
	@if [ -z "$(FACTORY_ADDRESS)" ]; then \
		echo "Usage: make getChallengesArray FACTORY_ADDRESS=<factory_address>"; \
		exit 1; \
	fi
	@echo "Get Challenges Array from factory $(FACTORY_ADDRESS)...."
	cast call $(FACTORY_ADDRESS) "getChallengesArray()" --rpc-url $(RPC_URL) --legacy	


decodeChallengesArray:
	@if [ -z "$(HEX_VALUE)" ]; then \
		echo "Usage: make decodeChallengesArray HEX_VALUE=<hex_value>"; \
		exit 1; \
	fi
	@echo "Decoding challenges array..."
	@cast --abi-decode "getChallengesArray()((address,address,string,string,uint16,uint16,uint256,uint256,bool)[])" "$(HEX_VALUE)" | \
	sed 's/\[\([^]]*\)\]/\n\1\n/g' | \
	sed 's/), /)\n/g' | \
	sed 's/(/\n===== Challenge =====\n/g' | \
	sed 's/)/\n===================\n/g' | \
	sed 's/, /\n/g' | \
	sed 's/\[.*\]//g' | \
	grep -v '^[[:space:]]*$$'

verifyContract:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make verifyContract CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Verifying contract at $(CHALLENGE_ADDRESS)..."
	@cast code $(CHALLENGE_ADDRESS) --rpc-url $(RPC_URL)

getContractFunctions:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getContractFunctions CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting functions from contract at $(CHALLENGE_ADDRESS)..."
	@cast storage $(CHALLENGE_ADDRESS) --rpc-url $(RPC_URL)

getTeamsCount:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getTeamsCount CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting teams count from challenge $(CHALLENGE_ADDRESS)..."
	@cast call $(CHALLENGE_ADDRESS) "getTeamsCount()(uint256)" --rpc-url $(RPC_URL)

getTeamsByTeamIndex:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(TEAM_INDEX)" ]; then \
		echo "Usage: make getTeamsByTeamIndex CHALLENGE_ADDRESS=<address> TEAM_INDEX=<index>"; \
		exit 1; \
	fi
	@echo "Getting team data for index $(TEAM_INDEX) from challenge $(CHALLENGE_ADDRESS)..."
	@cast call $(CHALLENGE_ADDRESS) "getTeamsByTeamIndex(uint16)(address[])" $(TEAM_INDEX) --rpc-url $(RPC_URL) | \
	sed 's/\[/\n=== Team Members ===\n/g' | \
	sed 's/\]/\n==================/g' | \
	sed 's/, /\n/g'

######### CHALLENGES DATA #########

getTotalChallenges:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ]; then \
		echo "Usage: make getTotalChallenges CHALLENGE_DATA_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting total challenges from challenge data $(CHALLENGE_DATA_ADDRESS)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getTotalChallenges()(uint256)" --rpc-url $(RPC_URL) --legacy

getChallengeId:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ] || [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getChallengeId CHALLENGE_DATA_ADDRESS=<address> CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting challenge id from challenge data $(CHALLENGE_DATA_ADDRESS) for challenge $(CHALLENGE_ADDRESS)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getChallengeId(address)(uint256)" $(CHALLENGE_ADDRESS) --rpc-url $(RPC_URL) --legacy

getChallengeAddress:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ] || [ -z "$(CHALLENGE_ID)" ]; then \
		echo "Usage: make getChallengeAddress CHALLENGE_DATA_ADDRESS=<address> CHALLENGE_ID=<id>"; \
		exit 1; \
	fi
	@echo "Getting challenge address from challenge data $(CHALLENGE_DATA_ADDRESS) for challenge id $(CHALLENGE_ID)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getChallengeAddress(uint256)(address)" $(CHALLENGE_ID) --rpc-url $(RPC_URL) --legacy	

getChallengesBatch:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ] || [ -z "$(START_INDEX)" ] || [ -z "$(SIZE)" ]; then \
		echo "Usage: make getChallengesBatch CHALLENGE_DATA_ADDRESS=<address> START_INDEX=<index> SIZE=<size>"; \
		exit 1; \
	fi
	@echo "Getting challenges batch from challenge data $(CHALLENGE_DATA_ADDRESS) starting at index $(START_INDEX) with size $(SIZE)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getChallengesBatch(uint256,uint256)(address[])" $(START_INDEX) $(SIZE) --rpc-url $(RPC_URL) --legacy

getPlayerChallenges:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ] || [ -z "$(PLAYER_ADDRESS)" ]; then \
		echo "Usage: make getPlayerChallenges CHALLENGE_DATA_ADDRESS=<address> PLAYER_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting challenges for player $(PLAYER_ADDRESS) from challenge data $(CHALLENGE_DATA_ADDRESS)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getPlayerChallenges(address)(address[])" $(PLAYER_ADDRESS) --rpc-url $(RPC_URL) --legacy

getPlayerChallengesCount:
	@if [ -z "$(CHALLENGE_DATA_ADDRESS)" ] || [ -z "$(PLAYER_ADDRESS)" ]; then \
		echo "Usage: make getPlayerChallengesCount CHALLENGE_DATA_ADDRESS=<address> PLAYER_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Getting challenges count for player $(PLAYER_ADDRESS) from challenge data $(CHALLENGE_DATA_ADDRESS)..."
	@cast call $(CHALLENGE_DATA_ADDRESS) "getPlayerChallengesCount(address)(uint256)" $(PLAYER_ADDRESS) --rpc-url $(RPC_URL) --legacy
