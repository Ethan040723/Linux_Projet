#!/bin/bash


# Mise à jour su système 
sudo apt update -y
sudo apt upgrade -y

# Installation de postgresql
sudo apt install -y curl git sudo postgresql postgresql-contrib

# Installation de Node.js
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  sudo apt install -y nodejs


# Installation de PNPM
sudo npm install -g pnpm


# Création de l'utilisateur PostgreSQL
PG_PASSWORD=$(openssl rand -base64 32)  
sudo -u postgres psql -c "CREATE USER ianick4real WITH PASSWORD '$PG_PASSWORD';" 

# Création de la base de données 
sudo -u postgres psql -c "CREATE DATABASE ghostfolio_db OWNER ianick4real;" 
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ghostfolio_db TO ianick4real;"

# Préparation du dossier du projet
sudo mkdir -p /opt/ghostfolio
sudo chown $USER:$USER /opt/ghostolio


cd /opt/ghostfolio

# Clonage du GitHub
git clone https://github.com/ghostfolio/ghostfolio.git .

# Installation des dépendences 
pnpm install

# Installer express 
pnpm add express

# Installer Keyv 
pnpm add keyv

# Création du fichier .env avec les variables de configuration
cat > "ghostfolio/.env" <<EOF
DATABASE_URL="postgresql://ianick4real:$PG_PASSWORD@localhost:5432/ghostfolio_db"
NODE_ENV=production
PORT=3333
ENABLE_SIGNUP=true

EOF

JWT_SECRET=$(openssl rand -hex 32) 
echo "JWT_SECRET_KEY=$JWT_SECRET" >> .env 
ACCESS_TOKEN_SALT=$(openssl rand -hex 32)
echo "ACCESS_TOKEN_SALT=$ACCESS_TOKEN_SALT" >> .env


# Compilation du projet 
pnpm run build:production

# Modification du json 
sed -i 's/node main/node dist\/apps\/api\/main.js/' package.json

# Démarrage du projet 

npm run start:production
