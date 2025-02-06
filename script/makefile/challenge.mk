createOrJoinTeamWithForge:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(TEAM_INDEX)" ]; then \
		echo "Usage: make createOrJoinTeamWithForge CHALLENGE_ADDRESS=<address> TEAM_INDEX=<index>"; \
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

claimVictoryWithForge:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make claimVictoryWithForge CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Réclamation de la victoire pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/ClaimVictory.s.sol:ClaimVictory \
		--sig "run(address)" \
		$(CHALLENGE_ADDRESS) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy

getDelayStartVictoryClaim:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getDelayStartVictoryClaim CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Récupération du délai de début de réclamation de victoire pour le challenge $(CHALLENGE_ADDRESS)"; \
	cast call $(CHALLENGE_ADDRESS) "getDelayStartVictoryClaim()(uint256)" \
		--rpc-url $(RPC_URL)

getDelayEndVictoryClaim:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getDelayEndVictoryClaim CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Récupération du délai de fin de réclamation de victoire pour le challenge $(CHALLENGE_ADDRESS)"; \
	cast call $(CHALLENGE_ADDRESS) "getDelayEndVictoryClaim()(uint256)" \
		--rpc-url $(RPC_URL)		

setDelayVictoryClaim:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(DELAY)" ] || [ -z "$(IS_START_DELAY)" ]; then \
		echo "Usage: make setDelayVictoryClaim CHALLENGE_ADDRESS=<address> DELAY=<delay> IS_START_DELAY=<true/false>"; \
		echo "Note: IS_START_DELAY=true pour le délai de début, false pour le délai de fin"; \
		exit 1; \
	fi
	@echo "Configuration du délai de $(shell if [ "$(IS_START_DELAY)" = "true" ]; then echo "début"; else echo "fin"; fi) de réclamation de victoire pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/SetDelayVictoryClaim.s.sol:SetDelayVictoryClaim \
		--sig "run(address,bool,uint256)" \
		$(CHALLENGE_ADDRESS) $(IS_START_DELAY) $(DELAY) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy

withdrawChallengePool:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make withdrawChallengePool CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Retrait du pool pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/WithdrawChallengePool.s.sol:WithdrawChallengePool \
		--sig "run(address)" \
		$(CHALLENGE_ADDRESS) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy

getWithdrawDate:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getWithdrawDate CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Calcul de la date possible de withdraw pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/GetWithdrawDate.s.sol:GetWithdrawDate \
		--sig "run(address)" \
		$(CHALLENGE_ADDRESS) \
		--rpc-url $(RPC_URL)

setDelayDisputeParticipation:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(DELAY)" ] || [ -z "$(IS_START_DELAY)" ]; then \
		echo "Usage: make setDelayDisputeParticipation CHALLENGE_ADDRESS=<address> DELAY=<delay> IS_START_DELAY=<true/false>"; \
		echo "Note: IS_START_DELAY=true pour le délai de début, false pour le délai de fin"; \
		exit 1; \
	fi
	@echo "Configuration du délai de $(shell if [ "$(IS_START_DELAY)" = "true" ]; then echo "début"; else echo "fin"; fi) de participation à la dispute pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/SetDelayDisputeParticipation.s.sol:SetDelayDisputeParticipation \
		--sig "run(address,bool,uint256)" \
		$(CHALLENGE_ADDRESS) $(IS_START_DELAY) $(DELAY) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy

getChallengePool:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getChallengePool CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Récupération du montant du pool pour le challenge $(CHALLENGE_ADDRESS)"; \
	cast call $(CHALLENGE_ADDRESS) "getChallengePool()(uint256)" \
		--rpc-url $(RPC_URL)

getPoolAmountForWinner:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make getPoolAmountForWinner CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Récupération du montant à distribuer à l'équipe gagnante pour le challenge $(CHALLENGE_ADDRESS)"; \
	cast call $(CHALLENGE_ADDRESS) "calculatePoolAmountToSendBackForWinnerTeam()(uint256)" \
		--rpc-url $(RPC_URL)

calculateAmountPerPlayer:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make calculateAmountPerPlayer CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Calcul du montant par joueur pour le challenge $(CHALLENGE_ADDRESS)"; \
	forge script script/contracts/challenge/CalculateAmountPerPlayer.s.sol:CalculateAmountPerPlayer \
		--sig "run(address)" \
		$(CHALLENGE_ADDRESS) \
		--rpc-url $(RPC_URL)

calculateRemainingAmounts:
	@if [ -z "$(CHALLENGE_ADDRESS)" ]; then \
		echo "Usage: make calculateRemainingAmounts CHALLENGE_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Calcul des montants restants pour l'admin..."
	@echo "1. Pool amount remaining for admin:"
	@echo "s_challengePool = $$(cast call $(CHALLENGE_ADDRESS) "getChallengePool()(uint256)" --rpc-url $(RPC_URL))"
	@echo "totalPoolAmountForWinner = $$(cast call $(CHALLENGE_ADDRESS) "calculatePoolAmountToSendBackForWinnerTeam()(uint256)" --rpc-url $(RPC_URL))"
	@echo ""
	@echo "2. Dispute pool amount remaining for admin:"
	@echo "s_disputePool = $$(cast call $(CHALLENGE_ADDRESS) "getDisputePool()(uint256)" --rpc-url $(RPC_URL))"
	@echo "amountDispute = $$(cast call $(CHALLENGE_ADDRESS) "getDisputeAmountParticipation()(uint256)" --rpc-url $(RPC_URL))"
	@echo ""
	@echo "Résultats des soustractions :"
	@s_challengePool=$$(cast call $(CHALLENGE_ADDRESS) "getChallengePool()(uint256)" --rpc-url $(RPC_URL)); \
	totalPoolAmountForWinner=$$(cast call $(CHALLENGE_ADDRESS) "calculatePoolAmountToSendBackForWinnerTeam()(uint256)" --rpc-url $(RPC_URL)); \
	s_disputePool=$$(cast call $(CHALLENGE_ADDRESS) "getDisputePool()(uint256)" --rpc-url $(RPC_URL)); \
	amountDispute=$$(cast call $(CHALLENGE_ADDRESS) "getDisputeAmountParticipation()(uint256)" --rpc-url $(RPC_URL)); \
	echo "poolAmountRemainingforAdmin = $$((s_challengePool - totalPoolAmountForWinner))"; \
	echo "disputePoolAmountRemainingForAdmin = $$((s_disputePool - amountDispute))"