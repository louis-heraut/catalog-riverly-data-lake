# STAC Browser Service

Service d'interface web pour naviguer dans des catalogues STAC hébergés sur S3.

## Prérequis
- Node.js 20+
- Apache2
- Un nom de domaine pointant vers ce serveur

## Installation

### 1. Configuration
```bash
cp .env.dist .env
nano .env
```

Remplir :
```bash
STAC_APP_NAME=STAC Browser
STAC_CATALOG_URL=https://.../.../catalog.json
DOMAIN=stac.example.domain.fr
APACHE_SERVE_DIR=/var/www/stac-browser
```

### 2. Installation et déploiement
```bash
make install   # Clone STAC Browser + installe Apache
make deploy    # Build + déploie sur Apache
```

### 3. HTTPS (recommandé)
```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d stac.example.inrae.fr
```

## Mise à jour du catalogue
Le catalogue STAC est lu en temps réel depuis le S3 — aucune action nécessaire quand les données changent.

Pour mettre à jour STAC Browser lui-même :
```bash
cd stac-browser && git pull && cd ..
make deploy
```

## Commandes
```bash
make install   # Installation initiale
make deploy    # Valide, build et déploie
make update    # Met à jour le service
make restart   # Redémarre Apache
make status    # Statut Apache
make logs      # Logs en temps réel
make uninstall # Désinstalle le service
```
