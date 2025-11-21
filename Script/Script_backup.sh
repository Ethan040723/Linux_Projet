#!/bin/bash

set -e

apt update
apt install -y restic rclone postgresql-client


echo "CREATION DU DEPOT RESTIC"

mkdir -p /opt/backups
export RESTIC_REPOSITORY="/opt/backups"
export RESTIC_PASSWORD="motdepasse"

restic init || true


echo "CONFIGURATION RCLONE"
mkdir -p /root/.config/rclone

cat <<EOF >/root/.config/rclone/rclone.conf
[dropbox]
type = dropbox
token = {"access_token":""}
EOF


echo "CREATION DU SCRIPT DE BACKUP"

mkdir -p /opt/ghostfolio

cat <<'EOF' >/opt/ghostfolio/backup.sh
#!/bin/bash
set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CONFIG RESTIC
export RESTIC_REPOSITORY="/opt/backups"
export RESTIC_PASSWORD="motdepasse"

# CONFIG POSTGRES
PGUSER="ghostfolio"
PGDATABASE="ghostfolio"
PGPASSWORD="pgpassword"
export PGPASSWORD

# DOSSIER A SAUVEGARDER
TARGET="/opt/ghostfolio"

# Dump PostgreSQL (horodaté)
DUMPFILE="/tmp/ghostfolio_$(date +%Y%m%d%H%M%S).sql"
pg_dump -U "$PGUSER" "$PGDATABASE" > "$DUMPFILE"

# Sauvegarde Restic
restic backup "$TARGET" "$DUMPFILE"

# Suppression du dump
rm "$DUMPFILE"

# Upload vers Dropbox
rclone sync /opt/backups dropbox:ghostfolio-backups
EOF

chmod +x /opt/ghostfolio/backup.sh


echo "CONFIGURATION DE CRON"

(crontab -l 2>/dev/null; echo "0 * * * * /opt/ghostfolio/backup.sh") | crontab -