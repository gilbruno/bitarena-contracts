#!/bin/bash

# Script pour exécuter les commandes setGame et sauvegarder les transactions en base de données
# Usage: ./run_games.sh

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
    local game_name="$2"
    
    echo "=========================================="
    echo "Exécution de la commande: $command"
    echo "=========================================="
    
    # Exécuter la commande make et capturer la sortie
    local output
    if output=$(eval "$command" 2>&1); then
        echo "✅ Commande exécutée avec succès"
        echo "📄 Sortie:"
        echo "$output"
        echo ""
        
        # Extraire le hash de transaction et le numéro de bloc depuis la sortie de cast send
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
            echo "🔗 Hash de transaction: $tx_hash"
            echo "📦 Numéro de bloc: $block_number"
            echo ""
            
            # Sauvegarder en base de données
            save_to_database "$game_name" "$tx_hash" "$block_number"
        else
            echo "❌ Erreur: Impossible d'extraire le hash de transaction ou le numéro de bloc"
            echo "Hash trouvé: $tx_hash"
            echo "Block number trouvé: $block_number"
            echo "Sortie complète: $output"
            return 1
        fi
    else
        echo "❌ Erreur lors de l'exécution de la commande: $output"
        return 1
    fi
}

# Fonction pour sauvegarder en base de données PostgreSQL
save_to_database() {
    local game_name="$1"
    local tx_hash="$2"
    local block_number="$3"
    
    echo "💾 Sauvegarde en base de données..."
    echo "   Table: Game"
    echo "   Name: $game_name"
    echo "   TxHash: $tx_hash"
    echo "   BlockNumber: $block_number"
    
    # Requête SQL pour insérer ou mettre à jour les données (UPSERT)
    local sql="
    WITH upsert AS (
        UPDATE public.\"Game\" 
        SET \"txHash\" = '$tx_hash', 
            \"blockNumber\" = $block_number
        WHERE name = '$game_name'
        RETURNING *
    )
    INSERT INTO public.\"Game\" (name, \"txHash\", \"blockNumber\")
    SELECT '$game_name', '$tx_hash', $block_number
    WHERE NOT EXISTS (SELECT 1 FROM upsert);
    "
    
    # Exécuter la requête avec psql et capturer l'erreur
    local error_output
    if error_output=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "$sql" 2>&1); then
        echo "✅ Données sauvegardées avec succès dans la table Game"
    else
        echo "❌ Erreur lors de la sauvegarde en base de données"
        echo "Erreur SQL: $error_output"
        echo "Requête SQL: $sql"
        return 1
    fi
    echo ""
}

# Fonction pour tester la connexion à la base de données
test_database_connection() {
    echo "🔍 Test de connexion à la base de données..."
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ Connexion à la base de données réussie"
        return 0
    else
        echo "❌ Impossible de se connecter à la base de données"
        echo "Vérifiez vos credentials dans le fichier .env"
        return 1
    fi
}

# Tester la connexion à la base de données
if ! test_database_connection; then
    exit 1
fi

echo "🎯 === Exécution des commandes setGame ==="
echo ""

# Exécuter les commandes setGame
execute_make_command "make setGame GAME_NAME=apex" "apex"
execute_make_command "make setGame GAME_NAME=csgo" "csgo"
execute_make_command "make setGame GAME_NAME=fortnite" "fortnite"

echo "🏁 === Fin de l'exécution des commandes setGame ==="
echo "✅ Toutes les commandes setGame ont été exécutées et les données sauvegardées en base."
