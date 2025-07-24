#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
DEPLOY_ENV="${DEPLOY_ENV:-production}"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup database
backup_database() {
    log "Creating database backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_file="$BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if docker-compose exec -T db mysqladmin ping -h localhost -u root -p"${DB_ROOT_PASSWORD:-root_password}" >/dev/null 2>&1; then
        docker-compose exec -T db mysqldump -u laravel -p"${DB_PASSWORD:-secure_password}" laravel > "$backup_file"
        log "Database backup created: $backup_file"
    else
        warning "Database not available, skipping backup"
    fi
}

# Function to run pre-deployment checks
pre_deployment_checks() {
    log "Running pre-deployment checks..."
    
    # Check if Docker is running
    if ! command_exists docker; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command_exists docker-compose; then
        error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        warning ".env file not found, creating from .env.example"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            warning "Please update .env file with production values"
        else
            error ".env.example file not found"
            exit 1
        fi
    fi
    
    # Check required environment variables
    local required_vars=("DB_PASSWORD" "APP_KEY")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            warning "$var is not set in environment"
        fi
    done
    
    log "Pre-deployment checks completed"
}

# Function to build and deploy
deploy() {
    log "Starting deployment process..."
    
    # Pull latest changes (if in git repository)
    if [ -d ".git" ]; then
        log "Pulling latest changes from repository..."
        git pull origin main || git pull origin master || warning "Failed to pull latest changes"
    fi
    
    # Build images
    log "Building Docker images..."
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
    else
        docker-compose build --no-cache
    fi
    
    # Stop existing containers
    log "Stopping existing containers..."
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
    else
        docker-compose down
    fi
    
    # Start new containers
    log "Starting new containers..."
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    else
        docker-compose up -d
    fi
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Run Laravel optimizations
    log "Running Laravel optimizations..."
    docker-compose exec -T app php artisan migrate --force
    docker-compose exec -T app php artisan config:cache
    docker-compose exec -T app php artisan route:cache
    docker-compose exec -T app php artisan view:cache
    
    # Create storage link if not exists
    docker-compose exec -T app php artisan storage:link || true
    
    log "Deployment completed successfully!"
}

# Function to run health checks
health_check() {
    log "Running health checks..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        info "Health check attempt $attempt/$max_attempts"
        
        # Check application health
        if curl -f -s http://localhost:8080/health >/dev/null; then
            log "Application health check passed"
            break
        else
            warning "Application health check failed, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        fi
        
        if [ $attempt -gt $max_attempts ]; then
            error "Application health check failed after $max_attempts attempts"
            return 1
        fi
    done
    
    # Check database connectivity
    if docker-compose exec -T db mysqladmin ping -h localhost -u root -p"${DB_ROOT_PASSWORD:-root_password}" >/dev/null 2>&1; then
        log "Database connectivity check passed"
    else
        error "Database connectivity check failed"
        return 1
    fi
    
    # Check Redis connectivity
    if docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        log "Redis connectivity check passed"
    else
        error "Redis connectivity check failed"
        return 1
    fi
    
    log "All health checks passed!"
}

# Function to rollback deployment
rollback() {
    error "Deployment failed, initiating rollback..."
    
    # Stop current containers
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
    else
        docker-compose down
    fi
    
    # Restore from backup if available
    local latest_backup=$(ls -t "$BACKUP_DIR"/db_backup_*.sql 2>/dev/null | head -n1)
    if [ -n "$latest_backup" ]; then
        warning "Restoring database from backup: $latest_backup"
        # Start database service
        docker-compose up -d db
        sleep 10
        docker-compose exec -T db mysql -u laravel -p"${DB_PASSWORD:-secure_password}" laravel < "$latest_backup"
    fi
    
    error "Rollback completed. Please check the logs and fix the issues."
    exit 1
}

# Main deployment function
main() {
    log "Starting Laravel Docker deployment..."
    
    # Load environment variables
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
    fi
    
    # Run pre-deployment checks
    pre_deployment_checks
    
    # Create database backup
    backup_database
    
    # Deploy application
    if deploy; then
        # Run health checks
        if health_check; then
            log "Deployment completed successfully!"
            info "Application is available at: http://localhost:${APP_PORT:-8080}"
        else
            rollback
        fi
    else
        rollback
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "health")
        health_check
        ;;
    "backup")
        backup_database
        ;;
    "rollback")
        rollback
        ;;
    *)
        echo "Usage: $0 {deploy|health|backup|rollback}"
        echo ""
        echo "Commands:"
        echo "  deploy   - Run full deployment process (default)"
        echo "  health   - Run health checks only"
        echo "  backup   - Create database backup only"
        echo "  rollback - Rollback deployment"
        exit 1
        ;;
esac
