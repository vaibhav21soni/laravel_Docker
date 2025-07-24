#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to run artisan commands
run_artisan() {
    cd /var/www/html/laravel-app
    php artisan "$@"
}

# Function to run composer commands
run_composer() {
    cd /var/www/html/laravel-app
    composer "$@"
}

# Function to run npm commands
run_npm() {
    cd /var/www/html/laravel-app
    npm "$@"
}

# Function to clear cache
clear_cache() {
    echo -e "${GREEN}Clearing Laravel cache...${NC}"
    cd /var/www/html/laravel-app
    php artisan config:clear
    php artisan cache:clear
    php artisan route:clear
    php artisan view:clear
    echo -e "${GREEN}Cache cleared successfully!${NC}"
}

# Function to optimize application
optimize() {
    echo -e "${GREEN}Optimizing Laravel application...${NC}"
    cd /var/www/html/laravel-app
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    echo -e "${GREEN}Application optimized successfully!${NC}"
}

# Show help message if no arguments provided
if [ $# -eq 0 ]; then
    echo -e "${GREEN}Laravel Container Commands${NC}"
    echo "Usage: $0 [command]"
    echo ""
    echo "Available commands:"
    echo "  artisan [command]    Run Laravel Artisan command"
    echo "  composer [command]   Run Composer command"
    echo "  npm [command]        Run NPM command"
    echo "  clear-cache         Clear Laravel cache"
    echo "  optimize           Optimize Laravel application"
    exit 1
fi

# Parse command
case "$1" in
    "artisan")
        shift
        run_artisan "$@"
        ;;
    "composer")
        shift
        run_composer "$@"
        ;;
    "npm")
        shift
        run_npm "$@"
        ;;
    "clear-cache")
        clear_cache
        ;;
    "optimize")
        optimize
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        exit 1
        ;;
esac
