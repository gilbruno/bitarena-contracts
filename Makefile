.PHONY: deploy

# Définir les variables pour les adresses des tokens et les paramètres de déploiement
# Remplacez par l'adresse de la factory une fois déployée
BITARENA_FACTORY_ADDRESS=  

deployFactory:
	@echo "Deploying the Bitarena Factory contract..."
	forge script script/DeployBitarenaFactory.s.sol:DeployBitarenaFactory --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY_ADMIN_FACTORY) --broadcast --legacy

generateFactoryAbi:
	@echo "Generate Factory ABI"
	forge build --silent && jq '.abi' ./out/BitarenaFactory.sol/BitarenaFactory.json > ./abi/BitarenaFactory.json