#!/bin/bash

# Met à jour la liste des paquets et installe les dernières versions des paquets du système
sudo apt update -y
sudo apt upgrade -y

# Installe les outils de base comme curl, git, sudo, et PostgreSQL (une base de données)
sudo apt install -y curl git sudo postgresql postgresql-contrib

# Installe Node.js version 22 à partir du dépôt officiel (pour utiliser JavaScript sur le serveur)
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
sudo apt install -y nodejs

# Installe PNPM globalement, un gestionnaire de paquets plus rapide que npm
sudo npm install -g pnpm

# Crée un utilisateur PostgreSQL avec un mot de passe sécurisé généré aléatoirement
PG_PASSWORD=$(openssl rand -base64 32)  # Génère un mot de passe sécurisé
# Crée un utilisateur PostgreSQL et lui attribue un mot de passe
sudo -u postgres psql -c "CREATE USER ianick4real WITH PASSWORD '$PG_PASSWORD';"

# Crée une base de données PostgreSQL appelée ghostfolio_db et attribue les droits à notre utilisateur
sudo -u postgres psql -c "CREATE DATABASE ghostfolio_db OWNER ianick4real;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ghostfolio_db TO ianick4real;"

# Crée un dossier pour le projet Ghostfolio dans /opt/ghostfolio
sudo mkdir -p /opt/ghostfolio
# Change les permissions pour que l'utilisateur actuel puisse travailler dans ce dossier
sudo chown $USER:$USER /opt/ghostfolio

# Change de répertoire et se place dans le dossier du projet
cd /opt/ghostfolio

# Clone le code du projet Ghostfolio depuis GitHub dans ce dossier
git clone https://github.com/ghostfolio/ghostfolio.git .

# Installe toutes les dépendances nécessaires à l'application avec PNPM
pnpm install

# Installe Express, un framework pour créer des applications web (si ce n'est pas déjà fait)
pnpm add express

# Installe Keyv, une bibliothèque pour gérer le cache dans l'application
pnpm add keyv

# Crée un fichier .env avec les variables de configuration nécessaires pour la base de données et l'application
cat > /opt/ghostfolio/.env <<EOF
DATABASE_URL="postgresql://ianick4real:$PG_PASSWORD@localhost:5432/ghostfolio_db"
NODE_ENV=production
PORT=3333
ENABLE_SIGNUP=true
JWT_SECRET_KEY="fb02c1968c7a4c6eb3ab69a9b5d1aecc"
ACCESS_TOKEN_SALT="d2a0f8c7e13b4f61a893f76de5c4c812"
EOF

# Vérifie si Express et Keyv sont bien installés en cherchant ces bibliothèques dans le dossier node_modules
ls node_modules | grep express
ls node_modules | grep keyv

# Compile le projet pour le rendre prêt à être utilisé en production
pnpm run build:production

# Modifie le fichier package.json pour qu'il utilise le fichier compilé (main.js) au lieu de l'ancien fichier
sed -i 's/node main/node dist\/apps\/api\/main.js/' package.json

# Démarre l'application Ghostfolio en mode production
npm run start:production
