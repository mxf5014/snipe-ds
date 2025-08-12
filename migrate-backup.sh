#!/bin/bash

# Snipe-IT Migration Backup Script
# This script creates a complete backup of your Snipe-IT Docker setup

set -e  # Exit on any error

echo "🚀 Starting Snipe-IT Migration Backup..."

# Configuration
BACKUP_DIR="snipe-migration-$(date +%Y%m%d-%H%M%S)"
PROJECT_NAME="snipe-ds"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "📁 Created backup directory: $BACKUP_DIR"

# Stop containers gracefully
echo "⏹️  Stopping containers..."
docker-compose down

# Backup Docker Compose configuration
echo "📋 Backing up configuration files..."
cp docker-compose.yml "$BACKUP_DIR/"
cp -r docker/ "$BACKUP_DIR/" 2>/dev/null || echo "⚠️  No docker directory found"

# Create .env template for new machine
echo "📝 Creating environment template..."
cat > "$BACKUP_DIR/.env.template" << 'EOF'
# --------------------------------------------
# REQUIRED: BASIC APP SETTINGS
# --------------------------------------------
APP_ENV=production
APP_DEBUG=false
APP_KEY=CHANGE_THIS_ON_NEW_MACHINE
APP_URL=http://localhost:8000
APP_TIMEZONE=US/Pacific
APP_LOCALE=en
APP_PORT=8000

# --------------------------------------------
# REQUIRED: DATABASE SETTINGS
# --------------------------------------------
DB_DATABASE=snipeit
DB_USERNAME=snipeit
DB_PASSWORD=CHANGE_THIS_PASSWORD
MYSQL_ROOT_PASSWORD=CHANGE_THIS_ROOT_PASSWORD

# --------------------------------------------
# OPTIONAL: MAIL SETTINGS (configure as needed)
# --------------------------------------------
MAIL_MAILER=smtp
MAIL_HOST=your-smtp-server.com
MAIL_PORT=587
MAIL_USERNAME=your-email@domain.com
MAIL_PASSWORD=your-email-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDR=your-email@domain.com
MAIL_FROM_NAME="Snipe-IT"

# --------------------------------------------
# OPTIONAL: SESSION SETTINGS
# --------------------------------------------
SESSION_LIFETIME=12000
EXPIRE_ON_CLOSE=false
ENCRYPT=false
COOKIE_NAME=snipeit_session
SECURE_COOKIES=false

# --------------------------------------------
# CACHE SETTINGS
# --------------------------------------------
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_DRIVER=redis
REDIS_HOST=redis
REDIS_PORT=6379
EOF

# Backup data volumes
echo "💾 Backing up database volume..."
docker run --rm \
    -v ${PROJECT_NAME}_db_data:/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine:latest \
    tar czf /backup/db_backup.tar.gz -C /data .

echo "📁 Backing up storage volume..."
docker run --rm \
    -v ${PROJECT_NAME}_storage:/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine:latest \
    tar czf /backup/storage_backup.tar.gz -C /data .

echo "🔄 Backing up Redis volume..."
docker run --rm \
    -v ${PROJECT_NAME}_redis_data:/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine:latest \
    tar czf /backup/redis_backup.tar.gz -C /data .

# Create migration instructions
cat > "$BACKUP_DIR/MIGRATION_INSTRUCTIONS.md" << 'EOF'
# Snipe-IT Migration Instructions

## On the NEW machine:

1. **Install Docker and Docker Compose**
2. **Copy this entire folder to the new machine**
3. **Run the restore script:**
   ```bash
   chmod +x migrate-restore.sh
   ./migrate-restore.sh
   ```

## Post-Migration Steps:

1. **Update .env file** with your new server details
2. **Test the application** at http://YOUR_NEW_IP:8000
3. **Update any DNS records** to point to new server
4. **Configure SSL/reverse proxy** if needed

## Backup Contents:
- ✅ Database (MariaDB)
- ✅ Application storage/uploads
- ✅ Redis cache/sessions
- ✅ Docker Compose configuration
- ✅ Environment template

## Troubleshooting:
If containers won't start, check:
- Docker service is running
- Ports 8000, 3306, 6379 are available
- .env file has correct values
- File permissions on storage directory
EOF

# Create restore script for new machine
cat > "$BACKUP_DIR/migrate-restore.sh" << 'EOF'
#!/bin/bash

# Snipe-IT Migration Restore Script
# Run this on the NEW machine

set -e

echo "🔄 Starting Snipe-IT Migration Restore..."

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ Error: docker-compose.yml not found. Are you in the migration directory?"
    exit 1
fi

# Check for backup files
for file in db_backup.tar.gz storage_backup.tar.gz redis_backup.tar.gz; do
    if [[ ! -f "$file" ]]; then
        echo "❌ Error: $file not found!"
        exit 1
    fi
done

# Create .env if it doesn't exist
if [[ ! -f ".env" ]]; then
    echo "📝 Creating .env from template..."
    cp .env.template .env
    echo "⚠️  IMPORTANT: Edit .env file with your settings before continuing!"
    echo "Press Enter when ready to continue..."
    read
fi

# Create volumes (without starting containers)
echo "📦 Creating Docker volumes..."
docker-compose up --no-start

# Restore data volumes
echo "💾 Restoring database..."
docker run --rm \
    -v snipe-ds_db_data:/data \
    -v "$(pwd)":/backup \
    alpine:latest \
    tar xzf /backup/db_backup.tar.gz -C /data

echo "📁 Restoring storage..."
docker run --rm \
    -v snipe-ds_storage:/data \
    -v "$(pwd)":/backup \
    alpine:latest \
    tar xzf /backup/storage_backup.tar.gz -C /data

echo "🔄 Restoring Redis..."
docker run --rm \
    -v snipe-ds_redis_data:/data \
    -v "$(pwd)":/backup \
    alpine:latest \
    tar xzf /backup/redis_backup.tar.gz -C /data

# Fix permissions
echo "🔧 Fixing permissions..."
docker run --rm \
    -v snipe-ds_storage:/data \
    alpine:latest \
    chown -R 1000:1000 /data

# Start containers
echo "🚀 Starting containers..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check container status
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "✅ Migration restore completed!"
echo ""
echo "🌐 Your Snipe-IT should be available at: http://localhost:8000"
echo "🔍 Check logs with: docker-compose logs -f"
echo "🛠️  If issues occur, check the MIGRATION_INSTRUCTIONS.md file"
EOF

chmod +x "$BACKUP_DIR/migrate-restore.sh"

# Restart containers (optional - user can decide)
echo ""
echo "✅ Backup completed successfully!"
echo ""
echo "📦 Backup location: $BACKUP_DIR"
echo "📝 Next steps:"
echo "   1. Copy the '$BACKUP_DIR' folder to your new machine"
echo "   2. Run the restore script on the new machine"
echo ""
echo "🔄 Would you like to restart your containers now? (y/n)"
read -r restart_choice
if [[ $restart_choice =~ ^[Yy]$ ]]; then
    echo "🚀 Restarting containers..."
    docker-compose up -d
    echo "✅ Containers restarted"
else
    echo "⏹️  Containers remain stopped. Run 'docker-compose up -d' when ready."
fi

echo ""
echo "🎉 Migration backup is ready!"
echo "📁 Transfer this folder to your new machine: $BACKUP_DIR"
