# Linux_Projet

## Context
Nous devons réaliser un serveur linux pour lancer le service ghostfolio, ce service est un tracking de portfolio sur des actions en bourses.

## Matériel 
Nous allons utiliser Debian13 pour installer le serveur. Pourquoi Debian est pas un autre OS linux car pour les server Debian permet une meilleur 


# Backups

## En utilisant le logiciel **Restic** , créer un script qui archive les données importante du service

### Etape 1 : Installer Restic

```bash
sudo apt install restic -y
```

Vérifier qu'il est bien installé : 

```bash
restic version
```
![screen](Screenshots/backup1.png)
### Etape 2 :  Choisir un emplacement pour les backups

On va commencer sur un dossier en local :

```bash
mkdir -p /opt/backups
```

### Etape 3 : Initialiser un dépot pour stocker les sauvegardes

```bash
export RESTIC_REPOSITORY=/opt/backups
```

définir un mot de passe **nécessaire** pour restaurer une backup
```bash
export RESTIC_PASSWORD=password
```

```bash
restic init
```

### Etape 4 : Choisir quels données sont importantes a sauvegarder :

- Les bases de données 
- les fichiers de config (.env, config...)

### Etape 5 : Ecrire le script 

```sh
#!/bin/bash

export RESTIC_REPOSITORY="/opt/backups"
export RESTIC_PASSWORD="motdepasse"

PGUSER="ghostfolio"
PGDATABASE="ghostfolio"
PGPASSWORD="pgpassword"
export PGPASSWORD

TARGET="/opt/ghostfolio"

DUMPFILE="/tmp/ghostfolio.sql"
pg_dump -U "$PGUSER" "$PGDATABASE" > "$DUMPFILE"

restic backup "$TARGET" "$DUMPFILE"

rm "$DUMPFILE"
```

Ensuite il faut donner les permissions au script : 

```bash
chmod +x /opt/ghostfolio/backup.sh
```

Puis l'exécuter, et vérifier dans /opt/backups que il y a les snapshots enregistré :
```bash
restic snapshots
```
![screen](Screenshots/backup2.png)
## Configurez le logiciel **cron** pour qu’il exécute ce script toutes les heures

### Etape 1 : Ouvrir cron : 

```bash
crontab -e
```

### Etape 2 : Ecrire cette ligne a la fin du fichier

Pour exécuter chaque heure : 0 * * * *

```bash
0 * * * * /opt/ghostfolio/backup.sh
```
![screen](Screenshots/backup3.png)
## En utilisant l’utilitaire rclone , transférez le backup sur un serveur distant (ex: Google Drive, dropbox)

### Etape 1 : Installer rclone :

```bash
sudo apt install rclone -y
```

### Etape 2 : Config rclone

```bash
rclone config
```

- Appuyer sur N pour crée un remote : (pour moi le nom sera 'dropbox')
- Choisir le type de stockage 'drop box' (13)
- Client ID : laisser vide 
- Client secret : vide
- auto config : oui
	- Autoriser dans le navigateur
 
![screen](Screenshots/backup4.png)

- taper 'q' pour quitter 

### Etape 3 : Tester d'envoyer un fichier sur dropbox 

```bash
echo test > /tmp/test.txt
```

```bash
rclone copy /tmp/test.txt dropbox:ghostfolio-backups
```
pour vérifier :
```bash
rclone ls dropbox:ghostfolio-backups
```

![screen](Screenshots/backup5.png)
il apparait, ça marche
### Etape 4 : Modifier le script pour pouvoir envoyer les backups 

Donc a la fin du script /opt/ghostfolio/backup.sh il faut ajouter :

```bash
rclone sync /home/ghostfolio/backups dropbox:ghostfolio-backups
```
![screen](Screenshots/backup6.png)
### Etape 5 : tester sur dropbox si le fichier est présent

exécuter le script backup.

Pour ma part j'ai eu une erreur qui me dit que cron ne trouve pas restic et pg_dump donc j'ai du rajouter cette ligne au début du script : 

```bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Maintenant le script ressemble a ça : 

```sh
#!/bin/bash  
  
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin  
  
# Config restic  
export RESTIC_REPOSITORY="/opt/backups"  
export RESTIC_PASSWORD="motdepasse"  
  
# Config postgre  
PGUSER="ghostfolio"  
PGDATABASE="ghostfolio"  
PGPASSWORD="pgpassword"  
export PGPASSWORD  
  
# Dossier a save  
TARGET="/opt/ghostfolio"  
  
# Dump Postgresql  
DUMPFILE="/tmp/ghostfolio.sql"  
pg_dump -U "$PGUSER" "$PGDATABASE" > "$DUMPFILE"  
  
# Sauvegarde Restic  
restic backup "$TARGET" "$DUMPFILE"  
  
# Suppression du dump  
rm "$DUMPFILE"  
  
# Upload vers dropbox  
rclone sync /home/ghostfolio/backups dropbox:ghostfolio-backups
```

Maintenant faire les test si la backup va sur dropbox :

Test d'upload :

```bash
rclone sync /opt/backups dropbox:ghostfolio-backups -P
```
si il y a un chargement c'est bon :
![screen](Screenshots/backup7.png)

Dans dropbox :

![screen](Screenshots/backup8.png)
la backup est la (par contre avec l'essai gratuit on a le droit qu'a 2go donc je ne peux pas mettre + que 1 backup)


### Script complet qui fait toute l'installation et la config des backups 


```bash
#!/bin/bash

set -e

apt update
apt install -y restic rclone postgresql-client


# CREATION DU DEPOT RESTIC

mkdir -p /opt/backups
export RESTIC_REPOSITORY="/opt/backups"
export RESTIC_PASSWORD="motdepasse"

restic init || true


# CONFIGURATION RCLONE
mkdir -p /root/.config/rclone

cat <<EOF >/root/.config/rclone/rclone.conf
[dropbox]
type = dropbox
token = {"access_token":""}
EOF


# CREATION DU SCRIPT DE BACKUP

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

# Dump PostgreSQL
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


# "CONFIGURATION DE CRON"

(crontab -l 2>/dev/null; echo "0 * * * * /opt/ghostfolio/backup.sh") | crontab -
```
