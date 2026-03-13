.PHONY: help install build deploy configure-apache restart status logs uninstall update publish-catalog validate

# Variables
STAC_BROWSER_DIR := stac-browser
PYTHON := python3
VENV := .python_env
BIN := $(VENV)/bin
PIP := $(BIN)/pip
PYTHON_VENV := $(BIN)/python

# Couleurs
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m

-include .env

help: ## Affiche cette aide
	@echo "$(GREEN)STAC Browser Service - Commandes disponibles$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

install:
	@echo "$(GREEN)Installation de STAC Browser...$(NC)"
	sudo git clone https://github.com/radiantearth/stac-browser $(STAC_BROWSER_DIR) || true
	cd $(STAC_BROWSER_DIR) && sudo npm install
	@echo "$(GREEN)Installation du virtualenv Python...$(NC)"
	sudo $(PYTHON) -m venv $(VENV)
	sudo $(PIP) install --upgrade pip
	sudo $(PIP) install -r requirements.txt
	$(MAKE) configure-apache
	@echo "$(GREEN)✓ Installation terminée$(NC)"

configure-apache: ## Configure le vhost Apache (une seule fois)
	@echo "$(GREEN)Configuration Apache...$(NC)"
	@echo "<VirtualHost *:80>\n\
	    ServerName $(DOMAIN)\n\
	    DocumentRoot $(APACHE_SERVE_DIR)\n\
	    <Directory $(APACHE_SERVE_DIR)>\n\
	        Options -Indexes\n\
	        AllowOverride All\n\
	        Require all granted\n\
	        FallbackResource /index.html\n\
	    </Directory>\n\
	    ErrorLog \$${APACHE_LOG_DIR}/stac-browser-error.log\n\
	    CustomLog \$${APACHE_LOG_DIR}/stac-browser-access.log combined\n\
	</VirtualHost>" | sudo tee /etc/apache2/sites-available/stac-browser.conf
	sudo a2ensite stac-browser.conf
	sudo a2dissite 000-default.conf || true
	sudo systemctl reload apache2
	@echo "$(GREEN)✓ Apache configuré$(NC)"

validate: ## Vérifie que le catalogue STAC racine est accessible
	@curl -sf "$(STAC_CATALOG_URL)" | python3 -m json.tool > /dev/null \
		&& echo "$(GREEN)✓ Catalogue accessible : $(STAC_CATALOG_URL)$(NC)" \
		|| echo "$(RED)✗ Catalogue inaccessible$(NC)"

build: ## Build STAC Browser avec la config
	@echo "$(GREEN)Build de STAC Browser...$(NC)"
	cd $(STAC_BROWSER_DIR) && \
	STAC_APP_NAME="$(STAC_APP_NAME)" \
	STAC_CATALOG_URL="$(STAC_CATALOG_URL)" \
	npm run build
	@echo "$(GREEN)✓ Build terminé$(NC)"

deploy: validate build ## Vérifie, build et déploie les fichiers
	@echo "$(GREEN)Déploiement sur Apache...$(NC)"
	sudo mkdir -p $(APACHE_SERVE_DIR)
	sudo cp -r $(STAC_BROWSER_DIR)/dist/. $(APACHE_SERVE_DIR)/
	sudo systemctl reload apache2
	@echo "$(GREEN)✓ Déployé sur http://$(DOMAIN)$(NC)"

update: ## Met à jour STAC Browser (git pull + npm install + redéploiement)
	@echo "$(GREEN)Mise à jour de STAC Browser...$(NC)"
	cd $(STAC_BROWSER_DIR) && sudo git pull
	cd $(STAC_BROWSER_DIR) && sudo npm install
	$(PIP) install --upgrade -r requirements.txt
	$(MAKE) deploy

restart: ## Redémarre Apache
	sudo systemctl restart apache2

status: ## Statut d'Apache
	sudo systemctl status apache2 --no-pager

logs: ## Logs Apache en temps réel
	sudo journalctl -u apache2 -f

publish-catalog: ## Upload le catalog.json racine sur S3
	@echo "$(GREEN)Publication du catalogue racine...$(NC)"
	$(PYTHON_VENV) publish_catalog.py
	@echo "$(GREEN)✓ Catalogue publié$(NC)"

uninstall: ## Désinstalle le service
	@echo "$(RED)Désinstallation...$(NC)"
	sudo a2dissite stac-browser.conf || true
	sudo rm -f /etc/apache2/sites-available/stac-browser.conf
	sudo rm -rf $(APACHE_SERVE_DIR)
	sudo systemctl reload apache2
	@echo "$(GREEN)✓ Désinstallé$(NC)"
