# Laravel Docker Makefile
# Provides convenient commands for development workflow

.PHONY: help build up down restart logs shell migrate seed test optimize clean fix-permissions clear-cache

# Default target
.DEFAULT_GOAL := help

# Colors
YELLOW := \033[33m
GREEN := \033[32m
RED := \033[31m
RESET := \033[0m

# Docker Compose files
COMPOSE_FILE := docker-compose.yml
COMPOSE_PROD_FILE := docker-compose.prod.yml

# Service names
APP_SERVICE := app
DB_SERVICE := db
REDIS_SERVICE := redis

help: ## Show this help message
	@echo "$(YELLOW)Laravel Docker Development Commands$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build Docker images
	@echo "$(YELLOW)Building Docker images...$(RESET)"
	docker-compose build --no-cache

build-base: ## Build base image only
	@echo "$(YELLOW)Building base image...$(RESET)"
	docker-compose build web

up: ## Start all services
	@echo "$(YELLOW)Starting services...$(RESET)"
	docker-compose up -d

up-build: ## Build and start all services
	@echo "$(YELLOW)Building and starting services...$(RESET)"
	docker-compose up -d --build

down: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(RESET)"
	docker-compose down

restart: ## Restart all services
	@echo "$(YELLOW)Restarting services...$(RESET)"
	docker-compose restart

logs: ## View application logs
	@echo "$(YELLOW)Viewing application logs...$(RESET)"
	docker-compose logs -f $(APP_SERVICE)

logs-all: ## View all services logs
	@echo "$(YELLOW)Viewing all services logs...$(RESET)"
	docker-compose logs -f

shell: ## Access application shell
	@echo "$(YELLOW)Accessing application shell...$(RESET)"
	docker-compose exec $(APP_SERVICE) sh

root-shell: ## Access application shell as root
	@echo "$(YELLOW)Accessing application shell as root...$(RESET)"
	docker-compose exec --user root $(APP_SERVICE) sh

db-shell: ## Access database shell
	@echo "$(YELLOW)Accessing database shell...$(RESET)"
	docker-compose exec $(DB_SERVICE) mysql -u laravel -p laravel

redis-shell: ## Access Redis shell
	@echo "$(YELLOW)Accessing Redis shell...$(RESET)"
	docker-compose exec $(REDIS_SERVICE) redis-cli

migrate: ## Run database migrations
	@echo "$(YELLOW)Running database migrations...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan migrate

migrate-fresh: ## Fresh database migrations with seeding
	@echo "$(YELLOW)Running fresh migrations with seeding...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan migrate:fresh --seed

seed: ## Seed database
	@echo "$(YELLOW)Seeding database...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan db:seed

rollback: ## Rollback database migrations
	@echo "$(YELLOW)Rolling back database migrations...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan migrate:rollback

test: ## Run PHPUnit tests
	@echo "$(YELLOW)Running PHPUnit tests...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan test

test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)Running tests with coverage...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan test --coverage

optimize: ## Optimize Laravel application
	@echo "$(YELLOW)Optimizing Laravel application...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan optimize

clear-cache: ## Clear all Laravel caches
	@echo "$(YELLOW)Clearing Laravel caches...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan config:clear
	docker-compose exec $(APP_SERVICE) php artisan cache:clear
	docker-compose exec $(APP_SERVICE) php artisan route:clear
	docker-compose exec $(APP_SERVICE) php artisan view:clear

key-generate: ## Generate application key
	@echo "$(YELLOW)Generating application key...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan key:generate

storage-link: ## Create storage symbolic link
	@echo "$(YELLOW)Creating storage symbolic link...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan storage:link

fix-permissions: ## Fix file permissions
	@echo "$(YELLOW)Fixing file permissions...$(RESET)"
	docker-compose exec --user root $(APP_SERVICE) chown -R www-data:www-data /var/www/html
	docker-compose exec --user root $(APP_SERVICE) chmod -R 775 storage bootstrap/cache

composer-install: ## Install Composer dependencies
	@echo "$(YELLOW)Installing Composer dependencies...$(RESET)"
	docker-compose exec $(APP_SERVICE) composer install

composer-update: ## Update Composer dependencies
	@echo "$(YELLOW)Updating Composer dependencies...$(RESET)"
	docker-compose exec $(APP_SERVICE) composer update

npm-install: ## Install NPM dependencies
	@echo "$(YELLOW)Installing NPM dependencies...$(RESET)"
	docker-compose exec $(APP_SERVICE) npm install

npm-dev: ## Run NPM development build
	@echo "$(YELLOW)Running NPM development build...$(RESET)"
	docker-compose exec $(APP_SERVICE) npm run dev

npm-build: ## Run NPM production build
	@echo "$(YELLOW)Running NPM production build...$(RESET)"
	docker-compose exec $(APP_SERVICE) npm run build

queue-work: ## Start queue worker
	@echo "$(YELLOW)Starting queue worker...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan queue:work

queue-restart: ## Restart queue workers
	@echo "$(YELLOW)Restarting queue workers...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan queue:restart

schedule-run: ## Run scheduled tasks
	@echo "$(YELLOW)Running scheduled tasks...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan schedule:run

tinker: ## Start Laravel Tinker
	@echo "$(YELLOW)Starting Laravel Tinker...$(RESET)"
	docker-compose exec $(APP_SERVICE) php artisan tinker

status: ## Show services status
	@echo "$(YELLOW)Services status:$(RESET)"
	docker-compose ps

stats: ## Show container resource usage
	@echo "$(YELLOW)Container resource usage:$(RESET)"
	docker stats --no-stream

clean: ## Clean up Docker resources
	@echo "$(YELLOW)Cleaning up Docker resources...$(RESET)"
	docker-compose down -v --remove-orphans
	docker system prune -f
	docker volume prune -f

clean-all: ## Clean up all Docker resources (including images)
	@echo "$(RED)WARNING: This will remove all Docker images!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		docker-compose down -v --remove-orphans; \
		docker system prune -af; \
		docker volume prune -f; \
		docker image prune -af; \
	fi

# Production commands
prod-up: ## Start services in production mode
	@echo "$(YELLOW)Starting services in production mode...$(RESET)"
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_PROD_FILE) up -d

prod-build: ## Build and start services in production mode
	@echo "$(YELLOW)Building and starting services in production mode...$(RESET)"
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_PROD_FILE) up -d --build

prod-down: ## Stop production services
	@echo "$(YELLOW)Stopping production services...$(RESET)"
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_PROD_FILE) down

# Health checks
health: ## Check services health
	@echo "$(YELLOW)Checking services health...$(RESET)"
	@echo "Application: $$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "FAILED")"
	@echo "Database: $$(docker-compose exec $(DB_SERVICE) mysqladmin ping -h localhost -u root -p$${DB_ROOT_PASSWORD:-root_password} 2>/dev/null && echo "OK" || echo "FAILED")"
	@echo "Redis: $$(docker-compose exec $(REDIS_SERVICE) redis-cli ping 2>/dev/null || echo "FAILED")"

# Backup and restore
backup-db: ## Backup database
	@echo "$(YELLOW)Backing up database...$(RESET)"
	docker-compose exec $(DB_SERVICE) mysqldump -u laravel -p$${DB_PASSWORD:-secure_password} laravel > backup_$$(date +%Y%m%d_%H%M%S).sql

restore-db: ## Restore database (usage: make restore-db FILE=backup.sql)
	@echo "$(YELLOW)Restoring database from $(FILE)...$(RESET)"
	@if [ -z "$(FILE)" ]; then echo "$(RED)Please specify FILE parameter$(RESET)"; exit 1; fi
	docker-compose exec -T $(DB_SERVICE) mysql -u laravel -p$${DB_PASSWORD:-secure_password} laravel < $(FILE)
