.PHONY: deploy

# Charger les variables d'environnement à partir du fichier .env
include .env
export $(shell sed 's/=.*//' .env)

# Définir les variables pour les adresses des tokens et les paramètres de déploiement
# Remplacez par l'adresse de la factory une fois déployée
BITARENA_FACTORY_ADDRESS=  

deployGames:
	@echo "Deploying the BitarenaGames contract..."
	forge script script/DeployBitarenaGames.s.sol:DeployBitarenaGames --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --broadcast --legacy

deployFactory:
	@echo "Deploying the Bitarena Factory contract..."
	forge script script/DeployBitarenaFactory.s.sol:DeployBitarenaFactory --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_FACTORY) --broadcast --legacy

generateFactoryAbi:
	@echo "Generate Factory ABI"
	forge build --silent && jq '.abi' ./out/BitarenaFactory.sol/BitarenaFactory.json > ./abi/BitarenaFactory.json

setGame:
	@if [ -z "$(GAME_NAME)" ]; then \
        echo "Usage: make setGame ARG=<value>"; \
        exit 1; \
    fi
	cast send $(ADDRESS_LAST_DEPLOYED_GAMES) "setGame(string)" "$(GAME_NAME)" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --legacy

setPlatform:
	@if [ -z "$(PLATFORM_NAME)" ]; then \
        echo "Usage: make setPlatform ARG=<value>"; \
        exit 1; \
    fi
	cast send $(ADDRESS_LAST_DEPLOYED_GAMES) "setPlatform(string)" "$(PLATFORM_NAME)" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_GAMES) --legacy

getGame:
	@if [ -z "$(GAME_INDEX)" ]; then \
        echo "Usage: make getGame ARG=<value>"; \
        exit 1; \
    fi
	cast call $(ADDRESS_LAST_DEPLOYED_GAMES) "getGameByIndex(uint256)" $(GAME_INDEX) --rpc-url $(RPC_URL) --legacy	

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