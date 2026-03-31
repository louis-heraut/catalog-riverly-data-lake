# STAC Browser Service - Catalog RiverLy Data Lake

<!-- badges: start -->
[![MADE WITH AI](https://raw.githubusercontent.com/louis-heraut/ai-label-badge/main/ai-label_badge-made-with-ai.svg)](https://ai-label.org/)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-green)](https://lifecycle.r-lib.org/articles/stages.html)
![](https://img.shields.io/github/last-commit/louis-heraut/catalog-riverly-data-lake)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)
<!-- badges: end -->

Interface web pour naviguer dans des catalogues STAC hébergés sur S3.

## Installation

### 1. Prérequis système
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git apache2 python3 python3-venv
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 2. Cloner le projet
```bash
sudo git clone https://github.com/louis-heraut/catalog-riverly-data-lake /opt/catalog-riverly-data-lake
sudo chown -R $USER:$USER /opt/catalog-riverly-data-lake
cd /opt/catalog-riverly-data-lake
```

### 3. Configuration
```bash
cp dist.env .env
nano .env
chmod 600 .env
```

Remplir les variables :
```bash
STAC_APP_NAME=STAC Browser
STAC_CATALOG_URL=https://s3-data.domain.fr/s3-bucket/stac-data/catalog.json
DOMAIN=catalog.data-lake.domain.fr
APACHE_SERVE_DIR=/var/www/stac-browser
S3_ACCESS_KEY=xxx
S3_SECRET_KEY=xxx
```

### 4. Installation et déploiement
```bash
make install  # Clone STAC Browser, installe les dépendances, configure Apache
make deploy   # Build et déploie sur Apache
```

### 5. HTTPS (recommandé)
```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache
```

## Mise à jour

### Mise à jour du catalogue
Le catalogue STAC est lu en temps réel depuis le S3 — aucune action nécessaire quand les données changent.

Si le fichier `catalog.json` racine est modifié :
```bash
make publish-catalog
```

### Mise à jour du projet (Makefile, config, catalog.json)
```bash
make update
```

### Mise à jour de STAC Browser
```bash
make update-browser
```

## Commandes disponibles
```bash
make install           # Installation initiale (Node.js, Apache, STAC Browser)
make validate          # Vérifie que le catalogue S3 est accessible
make configure-apache  # Reconfigure le vhost Apache
make deploy            # Build et déploie sur Apache
make update            # Met à jour le projet (Makefile, config, catalog.json)
make update-browser    # Met à jour STAC Browser et redéploie
make restart           # Redémarre Apache
make status            # Statut Apache
make logs              # Logs Apache en temps réel
make publish-catalog   # Upload le catalog.json racine sur S3
make uninstall         # Désinstalle le service
```

## Architecture

Ce service est une interface de navigation uniquement — il ne stocke aucune donnée.
Le catalogue STAC et les données sont hébergés sur S3 :
```
bucket: data-lake
├── stac-data/
│   ├── catalog.json          ← STAC_CATALOG_URL pointe ici
│   ├── safran/
│   │   ├── collection.json
│   │   └── items/
│   │       ├── item-01.json  ← référence l'URL S3 de la donnée
│   │       └── ...
│   └── arome/
│       ├── collection.json
│       └── items/
└── data/                     ← fichiers NetCDF, générés par le pipeline
    ├── safran/
    └── arome/
```