#!/bin/bash

# Script pour exécuter les commandes make et sauvegarder les transactions en base de données PostgreSQL
# Usage: ./execute_and_save.sh

# Vérifier que le fichier .env existe
if [ ! -f ".env" ]; then
    echo "❌ Erreur: Le fichier .env n'existe pas. Veuillez le créer avec les variables nécessaires."
    echo "Exemple de variables requises dans .env :"
    echo "DB_HOST=localhost"
    echo "DB_PORT=5432"
    echo "DB_NAME=bitarena"
    echo "DB_USER=your_username"
    echo "DB_PASSWORD=your_password"
    exit 1
fi

# Charger les variables d'environnement
source .env

# Vérifier que les variables de base de données sont définies
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ Erreur: Variables de base de données manquantes dans .env"
    echo "Veuillez définir: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
    exit 1
fi

# Fonction pour exécuter une commande make et capturer les informations de transaction
execute_make_command() {
    local command="$1"
    local table_name="$2"
    local name="$3"
    
    echo "Exécution de la commande: $command"
    
    # Exécuter la commande make et capturer la sortie
    local output
    if output=$(eval "$command" 2>&1); then
        echo "Commande exécutée avec succès"
        echo "Sortie: $output"
        
        # Extraire le hash de transaction et le numéro de bloc depuis la sortie de cast send
        # cast send retourne généralement quelque chose comme:
        # "blockHash" "0x..."
        # "blockNumber" "0x..."
        # "transactionHash" "0x..."
        local tx_hash=$(echo "$output" | grep -o '"transactionHash"[[:space:]]*"[^"]*"' | grep -o '0x[a-fA-F0-9]\{64\}')
        local block_number_hex=$(echo "$output" | grep -o '"blockNumber"[[:space:]]*"[^"]*"' | grep -o '0x[a-fA-F0-9]\+')
        
        # Si on ne trouve pas avec le format JSON, essayer d'autres formats
        if [ -z "$tx_hash" ]; then
            # Chercher transactionHash dans la sortie brute
            tx_hash=$(echo "$output" | grep -o 'transactionHash[[:space:]]*0x[a-fA-F0-9]\{64\}' | grep -o '0x[a-fA-F0-9]\{64\}')
        fi
        
        if [ -z "$block_number_hex" ]; then
            # Chercher blockNumber dans la sortie brute
            local block_number_dec=$(echo "$output" | grep -o 'blockNumber[[:space:]]*[0-9]\+' | grep -o '[0-9]\+')
            if [ -n "$block_number_dec" ]; then
                block_number_hex="0x$(printf '%x' $block_number_dec)"
            fi
        fi
        
        # Convertir le numéro de bloc hexadécimal en décimal
        local block_number=""
        if [ -n "$block_number_hex" ]; then
            block_number=$((block_number_hex))
        fi
        
        if [ -n "$tx_hash" ] && [ -n "$block_number" ]; then
            echo "Hash de transaction: $tx_hash"
            echo "Numéro de bloc: $block_number"
            
            # Sauvegarder en base de données
            save_to_database "$table_name" "$name" "$tx_hash" "$block_number"
        else
            echo "Erreur: Impossible d'extraire le hash de transaction ou le numéro de bloc"
            echo "Hash trouvé: $tx_hash"
            echo "Block number trouvé: $block_number"
            echo "Sortie complète: $output"
        fi
    else
        echo "Erreur lors de l'exécution de la commande: $output"
        return 1
    fi
}

# Fonction pour sauvegarder en base de données PostgreSQL
save_to_database() {
    local table="$1"
    local name="$2"
    local tx_hash="$3"
    local block_number="$4"
    
    echo "Sauvegarde en base de données..."
    echo "Table: $table"
    echo "Name: $name"
    echo "TxHash: $tx_hash"
    echo "BlockNumber: $block_number"
    
    # Requête SQL pour insérer ou mettre à jour les données (UPSERT)
    local sql="INSERT INTO public.\"$table\" (name, \"txHash\", \"blockNumber\") VALUES ('$name', '$tx_hash', $block_number) ON CONFLICT (name) DO UPDATE SET \"txHash\" = EXCLUDED.\"txHash\", \"blockNumber\" = EXCLUDED.\"blockNumber\", created_at = CURRENT_TIMESTAMP;"
    
    # Exécuter la requête avec psql
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "$sql"
    
    if [ $? -eq 0 ]; then
        echo "Données sauvegardées avec succès dans la table $table"
    else
        echo "Erreur lors de la sauvegarde en base de données"
    fi
}


# Fonction pour exécuter setMode avec formatage du nom
execute_set_mode() {
    local nb_teams="$1"
    local nb_players="$2"
    local mode_name="${nb_players}-${nb_players}"
    
    echo "Exécution de setMode avec NB_TEAMS=$nb_teams et NB_PLAYERS=$nb_players"
    echo "Nom du mode: $mode_name"
    
    local command="make setMode NB_TEAMS=$nb_teams NB_PLAYERS=$nb_players"
    execute_make_command "$command" "Mode" "$mode_name"
}

# Les variables d'environnement sont déjà chargées au début du script

echo "=== Début de l'exécution des commandes ==="

# Exécuter les commandes setPlatform
echo "=== Exécution des commandes setPlatform ==="
execute_make_command "make setPlatform PLATFORM_NAME=steam" "Platform" "steam"
execute_make_command "make setPlatform PLATFORM_NAME=ps5" "Platform" "ps5"

# Exécuter des commandes setGame
echo "=== Exécution des commandes setGame ==="
execute_make_command "make setGame GAME_NAME=apex" "Game" "apex"
execute_make_command "make setGame GAME_NAME=csgo" "Game" "csgo"
execute_make_command "make setGame GAME_NAME=fortnite" "Game" "fortnite"

# Exécuter des commandes setMode
echo "=== Exécution des commandes setMode ==="
execute_set_mode 2 1  # Créera un mode "2-1"
execute_set_mode 2 2  # Créera un mode "2-2"

echo "=== Fin de l'exécution des commandes ==="
echo "Toutes les commandes ont été exécutées et les données sauvegardées en base."
