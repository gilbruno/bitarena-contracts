# Configuration des chemins
AUDIT_DIR := audit
REPORTS_DIR := $(AUDIT_DIR)/audit-reports
ROOT_DIR := $(shell pwd)

# ==================================
# Configuration des outils
# ==================================

# Slither config
SLITHER_ARGS := \
	--filter-paths "lib|node_modules" \
	--exclude-dependencies \
	--config-file slither.config.json \
	--checklist \
	--markdown-root $(ROOT_DIR) \
	--solc-remaps "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/ @openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/"

# Mythril config
MYTHRIL_ARGS := \
	--solc-json mythril.config.json \
	--execution-timeout 600 \
	--max-depth 50 \
	--strategy bfs \
	--solv 0.8.22 \
	--mode full \
	--pruning-factor 2 \
	--transaction-count 5 \
	--solver-timeout 10000 \
	--parallel-solving \
	--loop-bound 3

# ==================================
# Cibles principales
# ==================================

$(REPORTS_DIR):
	@mkdir -p $(REPORTS_DIR)
	@echo "✅ Dossier audit configuré: $(ROOT_DIR)/$(REPORTS_DIR)"

# Analyse Slither (inchangée)
audit-slither: $(REPORTS_DIR)
	@if [ -z "$(CONTRACT_PATH)" ]; then \
		echo "❌ Error: CONTRACT_PATH not specified"; \
		echo "Usage: make audit-slither CONTRACT_PATH=chemin/vers/contrat.sol"; \
		exit 1; \
	fi
	@echo "🔍 Slither Analysis in progress..."
	@echo "Analysis of smart contrat: $(ROOT_DIR)/src/$(CONTRACT_PATH)"
	@( \
		echo "# Audit Report Slither" > "$(REPORTS_DIR)/slither-report.md"; \
		echo "## analyzed smart contract: $(CONTRACT_PATH)\n" >> "$(REPORTS_DIR)/slither-report.md"; \
		echo "## Identified vulnerabilities\n" >> "$(REPORTS_DIR)/slither-report.md"; \
		slither \
			"src/$(CONTRACT_PATH)" \
			$(SLITHER_ARGS) \
			--markdown >> "$(REPORTS_DIR)/slither-report.md" \
	) || true
	@if [ -s "$(REPORTS_DIR)/slither-report.md" ]; then \
		echo "✅ Slither report generated in $(REPORTS_DIR)/slither-report.md"; \
		echo "\n🔍 Summary of results :"; \
		grep -A 2 "Impact:" "$(REPORTS_DIR)/slither-report.md" || echo "No critical vulnerability detected"; \
	fi

# Nouvelle cible pour Mythril
audit-mythril: $(REPORTS_DIR)
	@if [ -z "$(CONTRACT_PATH)" ]; then \
		echo "❌ Erreur: CONTRACT_PATH not specified"; \
		echo "Usage: make audit-mythril CONTRACT_PATH=chemin/vers/contrat.sol"; \
		exit 1; \
	fi
	@echo "🔍 Mythril Analysis in progress..."
	@echo "Analysis of smart contract: $(ROOT_DIR)/src/$(CONTRACT_PATH)"
	@( \
		echo "# Audit Report Mythril" > "$(REPORTS_DIR)/mythril-report.md"; \
		echo "## analyzed smart contract: $(CONTRACT_PATH)\n" >> "$(REPORTS_DIR)/mythril-report.md"; \
		echo "## Identified vulnerabilities\n" >> "$(REPORTS_DIR)/mythril-report.md"; \
		myth analyze \
			"src/$(CONTRACT_PATH)" \
			$(MYTHRIL_ARGS) \
			--markdown >> "$(REPORTS_DIR)/mythril-report.md" \
	) || true
	@if [ -s "$(REPORTS_DIR)/mythril-report.md" ]; then \
		echo "✅ Mythril Report generated in $(REPORTS_DIR)/mythril-report.md"; \
		echo "\n🔍 Summary of results :"; \
		grep -A 2 "SWC ID:" "$(REPORTS_DIR)/mythril-report.md" || echo "No critical vulnerability detected"; \
	fi

# Nouvelle cible pour l'audit complet
audit-all: $(REPORTS_DIR)
	@if [ -z "$(CONTRACT_PATH)" ]; then \
		echo "❌ Error: CONTRACT_PATH not specified"; \
		echo "Usage: make audit-all CONTRACT_PATH=chemin/vers/contrat.sol"; \
		exit 1; \
	fi
	@echo "🔍 Start of full audit..."
	@echo "📁 Contrat: $(ROOT_DIR)/src/$(CONTRACT_PATH)"
	@echo "\n1️⃣ SLITHER Analysis"
	@make -f audit/audit.mk audit-slither CONTRACT_PATH=$(CONTRACT_PATH)
	@echo "\n2️⃣ MYTHRIL Analysis"
	@make -f audit/audit.mk audit-mythril CONTRACT_PATH=$(CONTRACT_PATH)
	@echo "\n✅ Full Audit completed"
	@echo "📊 Reports availaible in $(REPORTS_DIR):"
	@echo "   - slither-report.md"
	@echo "   - mythril-report.md"
	@echo "\n📝 Summary of found vulnerabilities:"
	@echo "\n=== Slither ==="
	@grep -A 2 "Impact:" "$(REPORTS_DIR)/slither-report.md" || echo "No Slither vulnerability detected"
	@echo "\n=== Mythril ==="
	@grep -A 2 "SWC ID:" "$(REPORTS_DIR)/mythril-report.md" || echo "No Mythril vulnerability detected"

.PHONY: audit-slither audit-mythril audit-all


# ==================================
# Analyse complète du projet
# ==================================

# Fonction pour trouver tous les fichiers .sol dans src/
SOLIDITY_FILES := $(shell find src -type f -name "*.sol")

# Nouvelle cible pour l'audit de tous les contrats
audit-project: $(REPORTS_DIR)
	@echo "🔍 Start of full audit of the project..."
	@echo "📁 Analyzed Directory: $(ROOT_DIR)/src"
	@echo "📝 Found smart contracts:"
	@for file in $(SOLIDITY_FILES); do \
		echo "   - $$file"; \
	done
	@echo "\n🚀 Start analysis..."
	@( \
		echo "# Full project audit report" > "$(REPORTS_DIR)/project-audit.md"; \
		echo "## Date: $$(date '+%Y-%m-%d %H:%M:%S')\n" >> "$(REPORTS_DIR)/project-audit.md"; \
		echo "## Smart Contracts analyzed\n" >> "$(REPORTS_DIR)/project-audit.md"; \
		for file in $(SOLIDITY_FILES); do \
			echo "- $$file" >> "$(REPORTS_DIR)/project-audit.md"; \
		done; \
		echo "\n---\n" >> "$(REPORTS_DIR)/project-audit.md"; \
	)
	@for contract in $(SOLIDITY_FILES); do \
		echo "\n📄 Analysis of $$contract..."; \
		contract_path=$${contract#src/}; \
		echo "\n# Analysis of $$contract_path" >> "$(REPORTS_DIR)/project-audit.md"; \
		echo "\n## Slither Report" >> "$(REPORTS_DIR)/project-audit.md"; \
		make -f audit/audit.mk audit-slither CONTRACT_PATH=$$contract_path 2>/dev/null || true; \
		cat "$(REPORTS_DIR)/slither-report.md" >> "$(REPORTS_DIR)/project-audit.md"; \
		echo "\n## Mythril Report" >> "$(REPORTS_DIR)/project-audit.md"; \
		make -f audit/audit.mk audit-mythril CONTRACT_PATH=$$contract_path 2>/dev/null || true; \
		cat "$(REPORTS_DIR)/mythril-report.md" >> "$(REPORTS_DIR)/project-audit.md"; \
		echo "\n---\n" >> "$(REPORTS_DIR)/project-audit.md"; \
	done
	@echo "\n✅ Project audit completed"
	@echo "📊 Full report available in: $(REPORTS_DIR)/project-audit.md"
	@echo "\n📝 Summary of vulnerabilities found :"
	@echo "\n=== Critical vulnerabilities ==="
	@grep -A 2 "Impact: High" "$(REPORTS_DIR)/project-audit.md" || echo "No critical vulnerabilities detected"
	@echo "\n=== Medium vulnerability ==="
	@grep -A 2 "Impact: Medium" "$(REPORTS_DIR)/project-audit.md" || echo "No medium vulnerability detected"
	@echo "\n=== Mythril SWC IDs ==="
	@grep -A 2 "SWC ID:" "$(REPORTS_DIR)/project-audit.md" || echo "No Mythril vulnerability detected"

# Mettre à jour .PHONY
.PHONY: audit-slither audit-mythril audit-all audit-project

