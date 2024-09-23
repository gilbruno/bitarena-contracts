.PHONY: deploy

# Définir les variables pour les adresses des tokens et les paramètres de déploiement
# Remplacez par l'adresse de la factory une fois déployée
BITARENA_FACTORY_ADDRESS=  

deployFactory:
	@echo "Deploying the Bitarena Factory contract..."
	forge script script/DeployBitarenaFactory.s.s.sol:DeployBitarenaFactory.s --broadcast --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

