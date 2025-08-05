#!/bin/bash

# Snipe-IT Render Startup Script
# This script is optimized for Render deployment

set -e

echo "🚀 Starting Snipe-IT on Render..."

# Function to handle environment variables
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

# Load environment variables
file_env APP_KEY
file_env DB_HOST
file_env DB_PORT
file_env DB_DATABASE
file_env DB_USERNAME
file_env DB_PASSWORD
file_env REDIS_HOST
file_env REDIS_PASSWORD
file_env REDIS_PORT
file_env MAIL_HOST
file_env MAIL_PORT
file_env MAIL_USERNAME
file_env MAIL_PASSWORD

# Generate APP_KEY if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:Change_this_key_or_snipe_will_get_ya" ]; then
    echo "🔑 Generating application key..."
    cd /var/www/html
    php artisan key:generate --force
fi

# Create data directories
echo "📁 Creating data directories..."
for dir in \
  'data/private_uploads' \
  'data/private_uploads/assets' \
  'data/private_uploads/accessories' \
  'data/private_uploads/audits' \
  'data/private_uploads/components' \
  'data/private_uploads/consumables' \
  'data/private_uploads/eula-pdfs' \
  'data/private_uploads/imports' \
  'data/private_uploads/assetmodels' \
  'data/private_uploads/users' \
  'data/private_uploads/licenses' \
  'data/private_uploads/signatures' \
  'data/uploads/accessories' \
  'data/uploads/assets' \
  'data/uploads/avatars' \
  'data/uploads/barcodes' \
  'data/uploads/categories' \
  'data/uploads/companies' \
  'data/uploads/components' \
  'data/uploads/consumables' \
  'data/uploads/departments' \
  'data/uploads/locations' \
  'data/uploads/manufacturers' \
  'data/uploads/models' \
  'data/uploads/suppliers' \
  'dumps' \
  'keys'
do
  [ ! -d "/var/lib/snipeit/$dir" ] && mkdir -p "/var/lib/snipeit/$dir"
done

# Set proper permissions
echo "🔐 Setting file permissions..."
chown -R docker:root /var/lib/snipeit/data/* 2>/dev/null || true
chown -R docker:root /var/lib/snipeit/dumps 2>/dev/null || true
chown -R docker:root /var/lib/snipeit/keys 2>/dev/null || true
chown -R docker:root /var/www/html/storage/framework/cache 2>/dev/null || true

# Wait for database to be ready
echo "⏳ Waiting for database..."
if [ -n "$DB_HOST" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then
    while ! mysql -h"$DB_HOST" -P"${DB_PORT:-3306}" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        echo "   Database not ready, waiting..."
        sleep 5
    done
    echo "✅ Database is ready"
fi

# Run database migrations (only if database is available)
if [ -n "$DB_HOST" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then
    echo "🗄️  Running database migrations..."
    cd /var/www/html
    php artisan migrate --force --no-interaction || echo "⚠️  Migration failed, continuing..."
fi

# Clear and cache configuration
echo "⚙️  Optimizing configuration..."
cd /var/www/html
php artisan config:clear || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Set proper permissions for logs
touch /var/www/html/storage/logs/laravel.log
chown -R docker:root /var/www/html/storage/logs/laravel.log 2>/dev/null || true

echo "✅ Snipe-IT startup complete!"

# Start supervisord
exec supervisord -c /supervisord.conf 