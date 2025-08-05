# Snipe-IT Docker-Only Setup Guide

This guide explains how to deploy Snipe-IT using Docker containers. This is the **only** supported deployment method.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM available
- At least 10GB disk space

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/grokability/snipe-it.git
   cd snipe-it
   ```

2. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Deploy:**
   ```bash
   ./deploy.sh
   ```

## Manual Setup

### 1. Environment Configuration

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` with your settings:
```bash
# Application
APP_NAME="Snipe-IT"
APP_ENV=production
APP_KEY=base64:your-key-here
APP_DEBUG=false
APP_URL=http://localhost:8000

# Database
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=snipeit
DB_USERNAME=snipeit
DB_PASSWORD=your-password
MYSQL_ROOT_PASSWORD=your-root-password

# Mail
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=admin@yourcompany.com
MAIL_FROM_NAME="${APP_NAME}"

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### 2. Start Services

```bash
docker-compose up -d
```

### 3. Initialize Database

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Create admin user
docker-compose exec app php artisan snipeit:create-user
```

### 4. Access the Application

Open your browser and go to: `http://localhost:8000`

## Services

The Docker setup includes:

- **app**: Snipe-IT web application (Apache + PHP)
- **db**: MariaDB database
- **redis**: Redis cache

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Update to latest version
docker-compose pull
docker-compose up -d

# Access application container
docker-compose exec app bash

# Run artisan commands
docker-compose exec app php artisan migrate
docker-compose exec app php artisan config:cache
```

## Backup and Restore

### Backup
```bash
# Backup database
docker-compose exec db mysqldump -u root -p snipeit > backup.sql

# Backup uploads
docker-compose exec app tar -czf uploads-backup.tar.gz /var/lib/snipeit/data/uploads
```

### Restore
```bash
# Restore database
docker-compose exec -T db mysql -u root -p snipeit < backup.sql

# Restore uploads
docker-compose exec app tar -xzf uploads-backup.tar.gz -C /var/lib/snipeit/data/
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   # Change port in docker-compose.yml
   ports:
     - "8001:80"  # Use port 8001 instead
   ```

2. **Database connection issues:**
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Restart database
   docker-compose restart db
   ```

3. **Permission issues:**
   ```bash
   # Fix storage permissions
   docker-compose exec app chown -R www-data:www-data /var/www/html/storage
   ```

### Logs

View logs for specific services:
```bash
docker-compose logs app    # Application logs
docker-compose logs db     # Database logs
docker-compose logs redis  # Redis logs
```

## Production Deployment

For production deployment:

1. **Use external database** (AWS RDS, Google Cloud SQL, etc.)
2. **Configure proper mail settings** (SMTP, SendGrid, etc.)
3. **Set up SSL/TLS certificates**
4. **Configure backups**
5. **Set up monitoring**

Update your `.env` file accordingly:
```bash
APP_URL=https://yourdomain.com
DB_HOST=your-external-db-host
MAIL_HOST=your-smtp-host
```

## Security Notes

- Change default passwords
- Use strong database passwords
- Configure proper file permissions
- Set up SSL/TLS in production
- Regular security updates
- Monitor logs for suspicious activity 