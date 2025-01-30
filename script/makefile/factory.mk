## Ex call : make intent-challenge \
    GAME="CS2" \
    PLATFORM="Steam" \
    NB_TEAMS=2 \
    NB_PLAYERS=2 \
    AMOUNT=0.01 \
    START_DATE="2024-03-15 14:30:00" \
    IS_PRIVATE=true
intentChallengeDeploymentWithForge:
	@if [ -z "$(GAME)" ] || [ -z "$(PLATFORM)" ] || [ -z "$(NB_TEAMS)" ] || [ -z "$(NB_PLAYERS)" ] || [ -z "$(AMOUNT)" ] || [ -z "$(START_DATE)" ]; then \
		echo "Usage: intentChallengeDeploymentWithForge GAME=<game> PLATFORM=<platform> NB_TEAMS=<teams> NB_PLAYERS=<players> AMOUNT=<eth> START_DATE='YYYY-MM-DD HH:MM:SS' IS_PRIVATE=<true/false>"; \
		exit 1; \
	fi
	@TIMESTAMP=$$(date -d "$(START_DATE)" +%s); \
	AMOUNT_WEI=$$(cast --to-wei $(AMOUNT) eth); \
	echo "Converting date $(START_DATE) to timestamp: $$TIMESTAMP"; \
	echo "Converting $(AMOUNT) ETH to wei: $$AMOUNT_WEI"; \
	forge script script/contracts/factory/IntentChallengeDeployment.s.sol:IntentChallengeDeployment \
		--sig "run(string,string,uint16,uint16,uint256,uint256,bool)" \
		"$(GAME)" "$(PLATFORM)" $(NB_TEAMS) $(NB_PLAYERS) $$AMOUNT_WEI $$TIMESTAMP $(IS_PRIVATE) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy \
		--gas-price 100000000000