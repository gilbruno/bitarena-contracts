createTeam:
	@if [ -z "$(CHALLENGE_ADDRESS)" ] || [ -z "$(TEAM_INDEX)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "Usage: make createTeam CHALLENGE_ADDRESS=<address> TEAM_INDEX=<index> AMOUNT=<eth>"; \
		exit 1; \
	fi
	@AMOUNT_WEI=$$(cast --to-wei $(AMOUNT) eth); \
	echo "Creating team $(TEAM_INDEX) in challenge $(CHALLENGE_ADDRESS)"; \
	echo "Sending $(AMOUNT) ETH ($$AMOUNT_WEI wei)"; \
	forge script script/CreateTeam.s.sol:CreateTeam \
		--sig "run(address,uint16)" \
		$(CHALLENGE_ADDRESS) $(TEAM_INDEX) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy \
		--gas-price 100000000000 \
		--value $$AMOUNT_WEI