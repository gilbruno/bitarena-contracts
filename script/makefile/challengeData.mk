# Vérifie si un contrat a le rôle d'enregistrement
hasRegisteringRole:
	@if [ -z "$(CONTRACT_ADDRESS)" ]; then \
		echo "Usage: make hasRegisteringRole CONTRACT_ADDRESS=<address>"; \
		exit 1; \
	fi
	@echo "Checking CONTRACTS_REGISTERING_ROLE for $(CONTRACT_ADDRESS)..."
	cast call $(ADDRESS_LAST_DEPLOYED_CHALLENGES_DATA) \
		"hasRole(bytes32,address)" \
		"0x16d8fb2e06c01ce79d33fb64c8b359c18ecd1ff13b8f60c0b3d0401e63f5e593" \
		$(CONTRACT_ADDRESS) \
		--rpc-url $(RPC_URL)

debugAuthorizeContractRegisteringWithForge:
	forge test \
		--fork-url $(RPC_URL) \
		--fork-block-number $(shell cast block-number --rpc-url $(RPC_URL)) \
		--match-test testAuthorizeContractsRegistering \
		-vvvv

authorize-contract:
	forge script script/contracts/challengeData/AuthorizeContract.s.sol:AuthorizeContract \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy