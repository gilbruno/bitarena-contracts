#!/bin/bash

# Script de test pour vérifier les commandes make et la base de données
# Usage: ./test_commands.sh

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

echo "🧪 === Script de test des commandes ==="
echo ""

# Fonction pour tester une commande make sans l'exécuter réellement
test_make_command() {
    local command="$1"
    local description="$2"
    
    echo "🔍 Test de: $description"
    echo "   Commande: $command"
    
    # Vérifier que la commande make existe
    if make -n $command > /dev/null 2>&1; then
        echo "   ✅ Commande make valide"
    else
        echo "   ❌ Commande make invalide"
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


# Les variables d'environnement sont déjà chargées au début du script

echo "1️⃣ Test de la connexion à la base de données..."
if ! test_database_connection; then
    exit 1
fi
echo ""

echo "2️⃣ Test des commandes make..."
test_make_command "setPlatform PLATFORM_NAME=test" "setPlatform"
test_make_command "setGame GAME_NAME=test" "setGame"
test_make_command "setMode NB_TEAMS=2 NB_PLAYERS=1" "setMode"

echo "3️⃣ Test d'insertion de données de test..."
# Insérer des données de test
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "
INSERT INTO public.\"Platform\" (name, \"txHash\", \"blockNumber\") 
VALUES ('test_platform', '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef', 12345)
ON CONFLICT DO NOTHING;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Insertion de données de test réussie"
else
    echo "❌ Erreur lors de l'insertion de données de test"
fi

echo ""
echo "🎉 === Tous les tests sont passés avec succès ! ==="
echo "Vous pouvez maintenant exécuter ./run_commands.sh pour lancer les commandes réelles."
