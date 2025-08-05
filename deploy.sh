#!/bin/bash

# Snipe-IT Docker Deployment Script
# This is the ONLY way to deploy Snipe-IT

set -e

echo "🚀 Snipe-IT Docker Deployment"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your configuration before continuing."
    echo "   Key settings to configure:"
    echo "   - APP_KEY (generate with: php artisan key:generate)"
    echo "   - DB_DATABASE, DB_USERNAME, DB_PASSWORD"
    echo "   - MAIL settings"
    exit 1
fi

echo "🔧 Starting Snipe-IT with Docker Compose..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

echo "🔍 Checking service status..."
docker-compose ps

echo "✅ Snipe-IT is now running!"
echo "🌐 Access the application at: http://localhost:8000"
echo ""
echo "📋 Useful commands:"
echo "   View logs: docker-compose logs -f"
echo "   Stop: docker-compose down"
echo "   Restart: docker-compose restart"
echo "   Update: docker-compose pull && docker-compose up -d" 