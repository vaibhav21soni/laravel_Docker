# Multi-stage Dockerfile for Laravel Application
FROM laravel-base:8.2 AS base

# Set working directory
WORKDIR /var/www/html

# Create application directory
RUN mkdir -p /var/www/html/laravel-app

# Copy application files
COPY --chown=www-data:www-data ./laravel-app /var/www/html/laravel-app

# Copy scripts
COPY --chown=root:root scripts/artisan.sh /usr/local/bin/artisan
RUN chmod +x /usr/local/bin/artisan

# Set working directory to Laravel app
WORKDIR /var/www/html/laravel-app

# Install Composer dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts

# Set proper permissions
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Production stage
FROM base AS production

# Switch to www-data user for security
USER www-data

# Optimize Laravel for production
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

# Development stage
FROM base AS development

# Install development dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Install additional development tools
USER root
RUN apk add --no-cache \
    php82-xdebug \
    inotify-tools \
    nodejs \
    npm

# Configure Xdebug for development
RUN echo "zend_extension=xdebug" >> /etc/php82/conf.d/xdebug.ini \
    && echo "xdebug.mode=debug,coverage" >> /etc/php82/conf.d/xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /etc/php82/conf.d/xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /etc/php82/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9003" >> /etc/php82/conf.d/xdebug.ini

# Install Node.js dependencies
COPY --chown=www-data:www-data ./laravel-app/package*.json ./
RUN npm install

# Switch back to www-data user
USER www-data

# Default stage (development)
FROM development AS default

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Start services
CMD ["/start.sh"]
