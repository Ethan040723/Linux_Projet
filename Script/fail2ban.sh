

# Mise à jour des paquets pour s'assurer que le système est à jour et propre
sudo apt update

# Installation de Nginx, nécessaire pour servir Ghostfolio
sudo apt install -y nginx

# Création de la configuration Nginx pour que Ghostfolio fonctionne sur le port HTTP standard (80)
sudo bash -c 'cat > /etc/nginx/sites-available/ghostfolio.conf <<EOF
server {
    listen 80;
    server_name _;

    # Définition des logs pour Fail2ban afin de suivre les tentatives d'accès
    access_log /var/log/nginx/ghostfolio.access.log;
    error_log /var/log/nginx/ghostfolio.error.log;

    # Configuration pour rediriger les requêtes vers Ghostfolio en local (port 3333)
    location / {
        proxy_pass http://127.0.0.1:3333;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF'

# Suppression de la page par défaut de Nginx pour éviter les conflits
sudo rm -f /etc/nginx/sites-enabled/default

# Activation de la configuration personnalisée de Ghostfolio
sudo ln -sf /etc/nginx/sites-available/ghostfolio.conf /etc/nginx/sites-enabled/ghostfolio.conf

# Redémarrage de Nginx pour appliquer la nouvelle configuration
sudo systemctl restart nginx

# Installation de Fail2ban pour protéger le serveur contre les tentatives d'intrusion
sudo apt install -y fail2ban

# Création d'une jail Fail2ban pour bloquer les tentatives de connexion avec des jetons invalides
sudo bash -c 'cat > /etc/fail2ban/jail.d/ghostfolio-invalid.conf <<EOF
[ghostfolio-invalid]
enabled = true
port = http,https
filter = ghostfolio-invalid
logpath = /var/log/nginx/ghostfolio.access.log
maxretry = 5
findtime = 5m
bantime = 1h
EOF'

# Création du filtre Fail2ban pour détecter les tentatives d'authentification avec des jetons invalides
sudo bash -c 'cat > /etc/fail2ban/filter.d/ghostfolio-invalid.conf <<EOF
[Definition]
failregex = ^<HOST> - .*POST /api/v1/auth/anonymous HTTP/1\.1" 403
EOF'

# Création d'une jail Fail2ban pour bloquer les attaques par énumération de pages (recherches de pages inexistantes)
sudo bash -c 'cat > /etc/fail2ban/jail.d/web-enum.conf <<EOF
[web-enum]
enabled = true
port = http,https
filter = web-enum
logpath = /var/log/nginx/ghostfolio.access.log
maxretry = 4
findtime = 2m
bantime = 1h
EOF'

# Création du filtre Fail2ban pour détecter les erreurs 404 liées à l'énumération de pages
sudo bash -c 'cat > /etc/fail2ban/filter.d/web-enum.conf <<EOF
[Definition]
failregex = ^<HOST> - .* "(GET|POST) .+ HTTP/[^"]+" 404
ignoreregex =
EOF'

# Redémarrage de Fail2ban pour appliquer les nouvelles règles de filtrage et de protection
sudo systemctl restart fail2ban
