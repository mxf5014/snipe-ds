#!/bin/bash

# Snipe-IT Production Deployment Script
# This script sets up Snipe-IT for production deployment

set -e

echo "🚀 Snipe-IT Production Deployment"
echo "=================================="

# Check if we're in a Docker environment
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "📦 Running in Docker container"
    
    # Wait for database to be ready
    echo "⏳ Waiting for database to be ready..."
    while ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        echo "   Database not ready, waiting..."
        sleep 5
    done
    echo "✅ Database is ready"
    
    # Generate application key if not set
    if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:Change_this_key_or_snipe_will_get_ya" ]; then
        echo "🔑 Generating application key..."
        php artisan key:generate
    fi
    
    # Run database migrations
    echo "🗄️  Running database migrations..."
    php artisan migrate --force
    
    # Clear and cache configuration
    echo "⚙️  Optimizing configuration..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    # Set proper permissions
    echo "🔐 Setting file permissions..."
    chown -R www-data:www-data /var/www/html/storage
    chown -R www-data:www-data /var/www/html/bootstrap/cache
    chmod -R 775 /var/www/html/storage
    chmod -R 775 /var/www/html/bootstrap/cache
    
    echo "✅ Production setup complete!"
    
else
    echo "❌ This script should be run inside a Docker container"
    exit 1
fi 