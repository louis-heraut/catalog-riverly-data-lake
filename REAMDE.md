# STAC Browser Service

Interface web pour naviguer dans des catalogues STAC hébergés sur S3.

## Installation

### 1. Prérequis système
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git nodejs npm apache2
```

### 2. Cloner le projet
```bash
sudo git clone https://github.com/louis-heraut/catalog-riverly-data-lake /opt/catalog-riverly-data-lake
cd /opt/catalog-riverly-data-lake
```

### 3. Configuration
```bash
cp dist.env .env
nano .env
```

Remplir les variables :
```bash
STAC_APP_NAME=Catalogue - RiverLy Data Lake
STAC_CATALOG_URL=https://s3-data.meso.umontpellier.fr/.../catalog.json
DOMAIN=catalog.riverly-data-lake.inrae.fr
APACHE_SERVE_DIR=/var/www/stac-browser
```

### 4. Installation et déploiement
```bash
make install   # Installe Node.js, Apache et clone STAC Browser
make deploy    # Build et déploie sur Apache
```

### 5. HTTPS (recommandé)
```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d catalog.riverly-data-lake.inrae.fr
```

## Mise à jour

### Mise à jour du catalogue

Le catalogue STAC est lu en temps réel depuis le S3 — aucune action nécessaire quand les données changent.

### Mise à jour de STAC Browser
```bash
make update
```

## Commandes disponibles
```bash
make install    # Installation initiale (Node.js, Apache, STAC Browser)
make deploy     # Build et déploie sur Apache
make update     # Met à jour STAC Browser et redéploie
make restart    # Redémarre Apache
make status     # Statut Apache
make logs       # Logs Apache en temps réel
make uninstall  # Désinstalle le service
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