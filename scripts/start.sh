#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Function to wait for service
wait_for_service() {
    local host=$1
    local port=$2
    local service=$3
    local timeout=${4:-30}
    
    log "Waiting for $service to be ready..."
    
    for i in $(seq 1 $timeout); do
        if nc -z "$host" "$port" 2>/dev/null; then
            log "$service is ready!"
            return 0
        fi
        sleep 1
    done
    
    error "$service is not ready after ${timeout}s"
    return 1
}

# Create necessary directories
log "Creating necessary directories..."
mkdir -p /var/log/nginx /var/log/php82 /var/run/nginx /var/run/php

# Set proper permissions
log "Setting proper permissions..."
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/log/nginx
chown -R www-data:www-data /var/log/php82

# Check if Laravel app exists
if [ ! -f "/var/www/html/laravel-app/artisan" ]; then
    error "Laravel application not found!"
    exit 1
fi

cd /var/www/html/laravel-app

# Wait for database if configured
if [ "${DB_CONNECTION:-}" = "mysql" ] && [ -n "${DB_HOST:-}" ]; then
    wait_for_service "${DB_HOST}" "${DB_PORT:-3306}" "MySQL database"
fi

# Wait for Redis if configured
if [ "${REDIS_HOST:-}" ]; then
    wait_for_service "${REDIS_HOST}" "${REDIS_PORT:-6379}" "Redis cache"
fi

# Generate application key if not exists
if [ -z "${APP_KEY:-}" ] || [ "${APP_KEY}" = "base64:" ]; then
    log "Generating application key..."
    php artisan key:generate --force
fi

# Run Laravel optimizations
log "Running Laravel optimizations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations if in development
if [ "${APP_ENV:-local}" != "production" ]; then
    log "Running database migrations..."
    php artisan migrate --force
fi

# Set proper storage permissions
log "Setting storage permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Create symbolic link for storage
if [ ! -L "public/storage" ]; then
    log "Creating storage symbolic link..."
    php artisan storage:link
fi

# Test PHP-FPM configuration
log "Testing PHP-FPM configuration..."
if ! php-fpm -t; then
    error "PHP-FPM configuration test failed!"
    exit 1
fi

# Test Nginx configuration
log "Testing Nginx configuration..."
if ! nginx -t; then
    error "Nginx configuration test failed!"
    exit 1
fi

# Start PHP-FPM
log "Starting PHP-FPM..."
php-fpm -D

# Check if PHP-FPM started successfully
sleep 2
if ! pgrep -f php-fpm > /dev/null; then
    error "PHP-FPM failed to start!"
    exit 1
fi

log "PHP-FPM started successfully"

# Start Nginx
log "Starting Nginx..."
exec nginx -g "daemon off;"
