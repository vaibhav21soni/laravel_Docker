# Laravel Docker Project Documentation

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [File Structure](#file-structure)
4. [Configuration](#configuration)
5. [Development Workflow](#development-workflow)
6. [Production Deployment](#production-deployment)
7. [Monitoring & Logging](#monitoring--logging)
8. [Troubleshooting](#troubleshooting)
9. [Performance Optimization](#performance-optimization)
10. [Security Considerations](#security-considerations)

## 🎯 Project Overview

This project provides a complete Docker environment for Laravel 12 applications with:

- **PHP 8.2** with optimized configuration
- **Nginx** web server with security headers
- **MySQL 8.0** database with proper initialization
- **Redis** for caching and sessions
- **Multi-stage builds** for development and production
- **Health checks** and monitoring
- **Automated deployment** scripts

## 🏗️ Architecture

### Container Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx + PHP   │    │     MySQL       │    │     Redis       │
│   (Laravel App) │    │   (Database)    │    │    (Cache)      │
│      :8080      │    │     :3306       │    │     :6379       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Docker        │
                    │   Network       │
                    │   (laravel)     │
                    └─────────────────┘
```

### Service Dependencies

- **app**: Depends on `db` and `redis`
- **queue**: Depends on `app`, `db`, and `redis`
- **scheduler**: Depends on `app` and `db`

## 📁 File Structure

```
laravel_docker/
├── docker/                     # Docker configuration files
│   ├── nginx/                 # Nginx configuration
│   │   ├── nginx.conf         # Main Nginx config
│   │   └── default.conf       # Server block config
│   ├── php/                   # PHP configuration
│   │   ├── php.ini           # PHP settings
│   │   ├── php-fpm.conf      # PHP-FPM config
│   │   └── www.conf          # PHP-FPM pool config
│   └── mysql/                 # MySQL configuration
│       └── init/              # Database initialization scripts
│           └── 01-create-database.sql
├── scripts/                   # Utility scripts
│   ├── start.sh              # Container startup script
│   └── deploy.sh             # Production deployment script
├── laravel-app/              # Laravel application files
├── docker-compose.yml        # Main Docker Compose config
├── docker-compose.prod.yml   # Production overrides
├── Dockerfile                # Application container
├── Dockerfile.base           # Base image with PHP/Nginx
├── Makefile                  # Development commands
├── .dockerignore             # Docker build exclusions
├── .env.example              # Environment template
├── .gitignore                # Git exclusions
├── README.md                 # Quick start guide
└── DOCUMENTATION.md          # This file
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_PORT` | Application port | 8080 |
| `APP_ENV` | Environment (local/production) | local |
| `APP_DEBUG` | Debug mode | true |
| `DB_DATABASE` | Database name | laravel |
| `DB_USERNAME` | Database user | laravel |
| `DB_PASSWORD` | Database password | secure_password |
| `REDIS_PASSWORD` | Redis password | (empty) |

### Docker Compose Profiles

- **Default**: `app`, `db`, `redis`
- **Queue**: Add `queue` service
- **Scheduler**: Add `scheduler` service
- **Production**: Optimized settings

## 🔄 Development Workflow

### Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd laravel_docker

# Copy environment file
cp .env.example .env

# Build and start services
make build
make up

# Initialize Laravel
make migrate
make key-generate
make storage-link
```

### Daily Development

```bash
# Start services
make up

# View logs
make logs

# Access shell
make shell

# Run tests
make test

# Stop services
make down
```

### Common Tasks

```bash
# Database operations
make migrate          # Run migrations
make migrate-fresh    # Fresh migrations with seeding
make seed            # Seed database
make rollback        # Rollback migrations

# Cache operations
make clear-cache     # Clear all caches
make optimize        # Optimize for production

# Composer operations
make composer-install # Install dependencies
make composer-update  # Update dependencies

# Asset operations
make npm-install     # Install NPM dependencies
make npm-dev         # Development build
make npm-build       # Production build
```

## 🚀 Production Deployment

### Automated Deployment

```bash
# Set environment
export DEPLOY_ENV=production

# Run deployment script
./scripts/deploy.sh
```

### Manual Deployment

```bash
# Build production images
make prod-build

# Start production services
make prod-up

# Run optimizations
make optimize
```

### Deployment Checklist

- [ ] Update `.env` with production values
- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Use strong database passwords
- [ ] Configure SSL/TLS termination
- [ ] Set up monitoring and logging
- [ ] Configure backups
- [ ] Test health endpoints

## 📊 Monitoring & Logging

### Health Checks

- **Application**: `http://localhost:8080/health`
- **Database**: Built-in Docker health checks
- **Redis**: Built-in Docker health checks

### Log Locations

- **Application**: `docker-compose logs app`
- **Nginx**: `/var/log/nginx/` in container
- **PHP-FPM**: `/var/log/php82/` in container
- **Laravel**: `laravel-app/storage/logs/`

### Monitoring Commands

```bash
# Check service status
make status

# View resource usage
make stats

# Run health checks
make health

# View specific service logs
docker-compose logs -f app
docker-compose logs -f db
docker-compose logs -f redis
```

## 🐛 Troubleshooting

### Common Issues

#### Permission Errors

```bash
# Fix permissions
make fix-permissions

# Or manually
docker-compose exec --user root app chown -R www-data:www-data /var/www/html
docker-compose exec --user root app chmod -R 775 storage bootstrap/cache
```

#### Database Connection Issues

```bash
# Check database status
docker-compose logs db

# Test connection
make db-shell

# Reset database
make migrate-fresh
```

#### Cache Issues

```bash
# Clear all caches
make clear-cache

# Restart services
make restart
```

#### Container Won't Start

```bash
# Check logs
docker-compose logs app

# Rebuild images
make build

# Check configuration
docker-compose config
```

### Debug Mode

Enable Xdebug for development:

```bash
# Set in .env
XDEBUG_MODE=debug
XDEBUG_CLIENT_HOST=host.docker.internal
XDEBUG_CLIENT_PORT=9003

# Rebuild container
make build
make up
```

## ⚡ Performance Optimization

### PHP Optimizations

- **OPcache**: Enabled with optimized settings
- **Memory limit**: 512M (configurable)
- **Execution time**: 300s for long-running tasks
- **File uploads**: 100M max size

### Nginx Optimizations

- **Gzip compression**: Enabled for static assets
- **Browser caching**: Long-term caching for assets
- **Buffer sizes**: Optimized for Laravel
- **Worker processes**: Auto-scaled

### Database Optimizations

- **InnoDB buffer pool**: 256M in production
- **Query cache**: Enabled
- **Connection limits**: 100 max connections

### Laravel Optimizations

```bash
# Production optimizations
make optimize

# Individual optimizations
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
docker-compose exec app php artisan event:cache
```

## 🔒 Security Considerations

### Container Security

- **Non-root user**: Containers run as `www-data`
- **Read-only filesystems**: Where possible
- **Resource limits**: CPU and memory limits in production
- **Network isolation**: Services communicate via Docker network

### Application Security

- **Security headers**: Implemented in Nginx
- **Rate limiting**: Configured for login endpoints
- **File access**: Restricted access to sensitive files
- **Environment variables**: Secrets not in code

### Database Security

- **User privileges**: Limited database user permissions
- **Password protection**: Strong passwords required
- **Network access**: Database not exposed externally
- **Backup encryption**: Consider encrypting backups

### Best Practices

1. **Regular updates**: Keep base images updated
2. **Secrets management**: Use Docker secrets or external vault
3. **SSL/TLS**: Always use HTTPS in production
4. **Monitoring**: Monitor for security events
5. **Backups**: Regular automated backups
6. **Access control**: Limit who can deploy

## 📚 Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [MySQL Documentation](https://dev.mysql.com/doc/)
