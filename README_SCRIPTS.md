# Scripts d'exécution et de sauvegarde des transactions

Ce dossier contient des scripts pour exécuter les commandes `make` et sauvegarder automatiquement les informations de transaction dans une base de données PostgreSQL.

## 📁 Fichiers

- `run_platforms.sh` - Script pour exécuter les commandes setPlatform
- `run_games.sh` - Script pour exécuter les commandes setGame
- `run_modes.sh` - Script pour exécuter les commandes setMode
- `run_commands.sh` - Script principal pour exécuter toutes les commandes
- `test_commands.sh` - Script de test pour vérifier la configuration
- `execute_and_save.sh` - Version alternative du script principal

## 🚀 Installation et configuration

### 1. Configuration de la base de données

Ajoutez les variables de base de données à votre fichier `.env` existant :

```bash
# Configuration de la base de données PostgreSQL
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="bitarena"
DB_USER="votre_nom_utilisateur"
DB_PASSWORD="votre_mot_de_passe"
```

Si vous n'avez pas encore de fichier `.env`, vous pouvez utiliser le fichier d'exemple :

```bash
cp env.example .env
# Puis modifiez .env avec vos valeurs réelles
```

### 2. Installation des dépendances

Assurez-vous d'avoir `psql` installé :

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql
```

### 3. Test de la configuration

Exécutez le script de test pour vérifier que tout est configuré correctement :

```bash
./test_commands.sh
```

## 🎯 Utilisation

### Exécution des commandes

Vous pouvez exécuter les commandes de plusieurs façons :

#### Option 1 : Scripts spécialisés (recommandé)

Exécutez chaque type de commande séparément :

```bash
# Exécuter uniquement les commandes setPlatform
./run_platforms.sh

# Exécuter uniquement les commandes setGame
./run_games.sh

# Exécuter uniquement les commandes setMode
./run_modes.sh
```

#### Option 2 : Script principal

Pour exécuter toutes les commandes en une fois :

```bash
./run_commands.sh
```

### Commandes exécutées

**Scripts spécialisés :**

- `run_platforms.sh` : `make setPlatform PLATFORM_NAME=steam` et `make setPlatform PLATFORM_NAME=ps5`
- `run_games.sh` : `make setGame GAME_NAME=apex`, `make setGame GAME_NAME=csgo` et `make setGame GAME_NAME=fortnite`
- `run_modes.sh` : `make setMode NB_TEAMS=2 NB_PLAYERS=1` (mode "1-1") et `make setMode NB_TEAMS=2 NB_PLAYERS=2` (mode "2-2")

**Script principal :**

- Toutes les commandes ci-dessus en une seule exécution

### Avantages des scripts spécialisés

- **🎯 Ciblage** : Exécutez uniquement le type de commande dont vous avez besoin
- **⚡ Performance** : Plus rapide si vous n'avez besoin que d'un type de commande
- **🔧 Maintenance** : Plus facile de modifier ou déboguer un type spécifique
- **📊 Monitoring** : Logs plus clairs pour chaque type de commande
- **🛡️ Sécurité** : Moins de risque d'erreur si vous ne voulez exécuter qu'une partie

### Structure des tables

Les scripts supposent que les tables suivantes existent déjà dans votre base de données :

#### Table `Platform`

- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR) - Nom de la plateforme
- `txHash` (VARCHAR) - Hash de la transaction
- `blockNumber` (BIGINT) - Numéro de bloc
- `created_at` (TIMESTAMP) - Date de création

#### Table `Game`

- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR) - Nom du jeu
- `txHash` (VARCHAR) - Hash de la transaction
- `blockNumber` (BIGINT) - Numéro de bloc
- `created_at` (TIMESTAMP) - Date de création

#### Table `Mode`

- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR) - Nom du mode (format "X-Y")
- `txHash` (VARCHAR) - Hash de la transaction
- `blockNumber` (BIGINT) - Numéro de bloc
- `created_at` (TIMESTAMP) - Date de création

### Création des tables

Si les tables n'existent pas encore, créez-les avec les requêtes SQL suivantes :

```sql
-- Table Platform
CREATE TABLE IF NOT EXISTS public."Platform" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    "txHash" VARCHAR(66) NOT NULL,
    "blockNumber" BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table Game
CREATE TABLE IF NOT EXISTS public."Game" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    "txHash" VARCHAR(66) NOT NULL,
    "blockNumber" BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table Mode
CREATE TABLE IF NOT EXISTS public."Mode" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    "txHash" VARCHAR(66) NOT NULL,
    "blockNumber" BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Comportement UPSERT

Les scripts utilisent des requêtes **UPSERT** avec le champ `name` comme pivot :

- **Si l'enregistrement n'existe pas** : Un nouvel enregistrement est créé
- **Si l'enregistrement existe déjà** (même `name`) : Les champs `txHash`, `blockNumber` et `created_at` sont mis à jour

**Logique UPSERT utilisée** :

```sql
WITH upsert AS (
    UPDATE table_name
    SET "txHash" = 'new_hash', "blockNumber" = 12345, created_at = CURRENT_TIMESTAMP
    WHERE name = 'platform_name'
    RETURNING *
)
INSERT INTO table_name (name, "txHash", "blockNumber")
SELECT 'platform_name', 'new_hash', 12345
WHERE NOT EXISTS (SELECT 1 FROM upsert);
```

Cela permet de :

- ✅ Éviter les doublons basés sur le champ `name`
- ✅ Mettre à jour les informations de transaction si une commande est relancée
- ✅ Fonctionner avec ou sans contraintes UNIQUE
- ✅ Garder un historique des modifications via `created_at`

## 🔧 Personnalisation

### Ajouter de nouvelles commandes

Pour ajouter de nouvelles commandes, modifiez le script `run_commands.sh` :

```bash
# Ajouter une nouvelle commande setPlatform
execute_make_command "make setPlatform PLATFORM_NAME=xbox" "Platform" "xbox"

# Ajouter une nouvelle commande setGame
execute_make_command "make setGame GAME_NAME=fortnite" "Game" "fortnite"

# Ajouter une nouvelle commande setMode
execute_set_mode 4 2  # Créera un mode "4-2"
```

### Exécuter des commandes individuelles

Vous pouvez aussi exécuter des commandes individuelles en modifiant temporairement le script ou en créant un script personnalisé.

## 🐛 Dépannage

### Erreur de connexion à la base de données

1. Vérifiez que PostgreSQL est en cours d'exécution
2. Vérifiez vos credentials dans le fichier `.env`
3. Testez la connexion manuellement :

```bash
psql -h localhost -p 5432 -d bitarena -U votre_utilisateur
```

### Erreur lors de la sauvegarde en base de données

Si vous obtenez une erreur "Erreur lors de la sauvegarde en base de données" :

1. **Créez les tables** avec les contraintes UNIQUE :

   ```bash
   ./setup_database.sh
   ```

2. **Vérifiez que les tables existent** :

   ```bash
   psql -h localhost -p 5432 -d bitarena -U votre_utilisateur -c "\dt public.*"
   ```

3. **Vérifiez les contraintes UNIQUE** :
   ```bash
   psql -h localhost -p 5432 -d bitarena -U votre_utilisateur -c "SELECT constraint_name, table_name FROM information_schema.table_constraints WHERE constraint_type = 'UNIQUE' AND table_schema = 'public';"
   ```

### Erreur lors de l'extraction des informations de transaction

Le script essaie plusieurs méthodes pour extraire le hash de transaction et le numéro de bloc. Si cela échoue :

1. Vérifiez que la commande `make` s'exécute correctement
2. Vérifiez que `cast send` retourne les informations attendues
3. Consultez la sortie complète dans les logs du script

### Erreur de permissions

Assurez-vous que les scripts sont exécutables :

```bash
chmod +x *.sh
```

## 📝 Logs

Le script affiche des logs détaillés avec des emojis pour faciliter le suivi :

- ✅ Succès
- ❌ Erreur
- 🔍 Test/Recherche
- 💾 Sauvegarde
- 🚀 Début/Fin

## 🔒 Sécurité

- Ne commitez jamais le fichier `.env` avec des credentials réels
- Utilisez des utilisateurs de base de données avec des permissions limitées
- Le fichier `.env` est déjà dans `.gitignore` pour éviter les commits accidentels
- Considérez l'utilisation de variables d'environnement système pour les credentials en production
