createOrJoinTeamWithForge:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(TEAM_INDEX)" ]; then \
		echo "Usage: make createOrJoinTeam CHALLENGE_ADDRESS=<address> TEAM_INDEX=<index>"; \
		echo "Note: TEAM_INDEX=0 pour créer une nouvelle équipe, >0 pour rejoindre une équipe existante"; \
		exit 1; \
	fi
	@echo "Création/Rejoindre équipe $(TEAM_INDEX) dans le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/CreateOrJoinTeam.s.sol:CreateOrJoinTeam \
		--sig "run(address,uint16)" \
		$(CHALLENGE_ADDRESS) $(TEAM_INDEX) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy