.PHONY: help install build deploy restart status logs uninstall

# Variables
STAC_BROWSER_DIR := stac-browser
CONFIG := config.json

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

install: ## Clone et installe STAC Browser
	@echo "$(GREEN)Installation de STAC Browser...$(NC)"
	sudo apt install -y nodejs npm apache2
	git clone https://github.com/radiantearth/stac-browser $(STAC_BROWSER_DIR) || true
	cd $(STAC_BROWSER_DIR) && npm install
	@echo "$(GREEN)✓ Installation terminée$(NC)"

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

deploy: validate build ## Vérifie, build et déploie
	@echo "$(GREEN)Déploiement sur Apache...$(NC)"
	sudo mkdir -p $(APACHE_SERVE_DIR)
	sudo cp -r $(STAC_BROWSER_DIR)/dist/. $(APACHE_SERVE_DIR)/
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
	@echo "$(GREEN)✓ Déployé sur http://$(DOMAIN)$(NC)"

update: ## Met à jour STAC Browser (git pull + npm install + redéploiement)
	@echo "$(GREEN)Mise à jour de STAC Browser...$(NC)"
	cd $(STAC_BROWSER_DIR) && git pull
	cd $(STAC_BROWSER_DIR) && npm install
	$(MAKE) deploy
	@echo "$(GREEN)✓ Mis à jour et redéployé$(NC)"

restart: ## Redémarre Apache
	sudo systemctl restart apache2

status: ## Statut d'Apache
	sudo systemctl status apache2 --no-pager

logs: ## Logs Apache en temps réel
	sudo journalctl -u apache2 -f

uninstall: ## Désinstalle le service
	@echo "$(RED)Désinstallation...$(NC)"
	sudo a2dissite stac-browser.conf || true
	sudo rm -f /etc/apache2/sites-available/stac-browser.conf
	sudo rm -rf $(APACHE_SERVE_DIR)
	sudo systemctl reload apache2
	@echo "$(GREEN)✓ Désinstallé$(NC)" 
