# Laravel Docker Setup

A complete Docker environment for Laravel 12 applications with PHP 8.2, Nginx, and MySQL support.

## 🚀 Features

- **Laravel 12** with PHP 8.2
- **Nginx** web server
- **MySQL** database support
- **Multi-stage Docker builds** for optimization
- **Development and Production** configurations
- **Automated permissions** and caching
- **Health checks** and monitoring
- **Easy deployment** with Docker Compose

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## 🛠️ Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd laravel_docker
cp .env.example .env
```

### 2. Configure Environment
Edit `.env` with your database credentials:
```env
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secure_password
```

### 3. Build and Run
```bash
# Build and start all services
docker-compose up -d --build

# Or use the Makefile
make build
make up
```

### 4. Initialize Application
```bash
# Run migrations and seed database
make migrate
make seed

# Generate application key
make key-generate
```

## 🔧 Development Commands

### Host Machine Commands (Using Makefile)

These commands are run from your host machine:

```bash
# Service management
make up              # Start services
make down            # Stop services
make restart         # Restart services
make build           # Rebuild containers

# Laravel commands
make migrate         # Run migrations
make seed            # Seed database
make test           # Run tests
make clear-cache    # Clear cache
make optimize       # Optimize for production

# Development tools
make shell          # Access container shell
make logs           # View logs
make status         # Check service status
```

### Container Commands

These commands are available inside the container:

```bash
# Access container shell first
make shell

# Then use the artisan command
artisan artisan migrate        # Run migrations
artisan composer update        # Update dependencies
artisan npm install           # Install NPM packages
artisan clear-cache          # Clear Laravel cache
artisan optimize            # Optimize application
```

Or run directly from host:

```bash
docker-compose exec app artisan artisan migrate
docker-compose exec app artisan composer update
docker-compose exec app artisan npm install
```

## 🐳 Docker Services

| Service | Port | Description |
|---------|------|-------------|
| **app** | 8080 | Laravel application with Nginx |
| **db** | 3306 | MySQL database server |
| **redis** | 6379 | Redis cache server |

## 🚀 Production Deployment

### 1. Use Production Configuration
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 2. Environment Variables
Set these environment variables for production:
```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=your-32-character-secret-key
DB_PASSWORD=secure-production-password
```

### 3. SSL/TLS Setup
Configure your reverse proxy (nginx, traefik, etc.) for SSL termination.

## 📊 Monitoring & Health Checks

- **Application health**: `http://localhost:8080/health`
- **Database connectivity**: Built-in health checks
- **Container status**: `docker-compose ps`
- **Resource usage**: `docker stats`

## 🐛 Troubleshooting

### Common Issues

**Permission Denied Errors:**
```bash
make fix-permissions
# or
docker-compose exec app chmod -R 755 storage bootstrap/cache
```

**Database Connection Issues:**
```bash
# Check database service
docker-compose logs db

# Test connection
docker-compose exec app artisan artisan migrate:status
```

**Cache Issues:**
```bash
make clear-cache
# or inside container:
artisan clear-cache
```

## 📝 Development Workflow

1. **Make changes** to your Laravel application
2. **Test locally** using `make test`
3. **Build and deploy** using `make build && make up`
4. **Monitor logs** using `make logs`
5. **Debug issues** using `make shell`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

## 🆘 Support

- **Documentation**: Check this README and inline comments
- **Issues**: Create an issue in the repository
- **Laravel Docs**: https://laravel.com/docs
- **Docker Docs**: https://docs.docker.com/

---

**Happy Coding! 🎉**
