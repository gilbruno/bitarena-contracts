#!/bin/bash

# Script simple pour tester la connexion à la base de données
# Usage: ./test_db_connection.sh

# Vérifier que le fichier .env existe
if [ ! -f ".env" ]; then
    echo "❌ Erreur: Le fichier .env n'existe pas."
    echo "Créez un fichier .env avec vos variables de base de données :"
    echo "DB_HOST=localhost"
    echo "DB_PORT=5432"
    echo "DB_NAME=bitarena"
    echo "DB_USER=your_username"
    echo "DB_PASSWORD=your_password"
    exit 1
fi

# Charger les variables d'environnement
source .env

# Vérifier que les variables sont définies
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ Erreur: Variables de base de données manquantes dans .env"
    echo "Variables requises: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
    exit 1
fi

echo "🔍 Test de connexion à la base de données..."
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Test 1: Connexion basique
echo "1️⃣ Test de connexion basique..."
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "SELECT 1 as test;" > /dev/null 2>&1; then
    echo "✅ Connexion réussie !"
else
    echo "❌ Échec de la connexion"
    echo "Vérifiez vos credentials et que PostgreSQL est en cours d'exécution"
    exit 1
fi

# Test 2: Version de PostgreSQL
echo ""
echo "2️⃣ Test de version PostgreSQL..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "SELECT version();" 2>/dev/null | head -1

# Test 3: Liste des tables existantes
echo ""
echo "3️⃣ Tables existantes dans le schéma public:"
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "\dt public.*" 2>/dev/null || echo "Aucune table trouvée"

# Test 4: Test d'écriture (création d'une table temporaire)
echo ""
echo "4️⃣ Test d'écriture..."
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "
CREATE TEMP TABLE test_connection (id SERIAL, test_text TEXT);
INSERT INTO test_connection (test_text) VALUES ('test');
SELECT 'Écriture réussie' as result;
DROP TABLE test_connection;
" > /dev/null 2>&1; then
    echo "✅ Test d'écriture réussi !"
else
    echo "❌ Échec du test d'écriture"
    echo "Vérifiez les permissions de votre utilisateur"
fi

echo ""
echo "🎉 Test de connexion terminé !"
