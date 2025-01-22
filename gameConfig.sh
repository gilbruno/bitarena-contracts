#!/bin/bash

#--- Vérifier si le fichier .env existe
if [ ! -f .env ]; then
    echo "Erreur: Le fichier .env est manquant"
    exit 1
fi

#--- Charger les variables d'environnement
source .env

echo "=== Configuration d'un nouveau jeu et d'une nouvelle plateforme ==="

#--- Configurer la plateforme
echo "Configuration de la plateforme 'Steam'..."
make setPlatform PLATFORM_NAME="Steam"
echo "=== Configuration terminée ==="

#--- Attendre quelques secondes pour que la transaction soit minée
echo "Attente de la confirmation de la transaction..."
sleep 5

#--- Configurer le jeu
echo "Configuration du jeu 'FarCry'..."
make setGame GAME_NAME="FarCry"



#--- Vérification optionnelle
echo "Vérification des jeux configurés..."
make getGames BITARENA_GAMES_ADDRESS=$ADDRESS_LAST_DEPLOYED_GAMES