# Snipe-IT Render Deployment Guide

This guide will help you deploy Snipe-IT on Render using Docker containers.

## Prerequisites

- A Render account
- GitHub repository with Snipe-IT code
- SMTP service for email (Gmail, SendGrid, etc.)

## Deployment Options

### Option 1: Using render.yaml (Recommended)

1. **Connect your GitHub repository to Render**
   - Go to Render Dashboard
   - Click "New +" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect the `render.yaml` file

2. **Configure Environment Variables**
   After the initial deployment, you'll need to set these environment variables in Render:

   **Required Variables:**
   ```
   APP_URL=https://your-app-name.onrender.com
   MAIL_USERNAME=your-smtp-username
   MAIL_PASSWORD=your-smtp-password
   MAIL_FROM_ADDRESS=noreply@yourdomain.com
   ```

   **Optional Variables:**
   ```
   APP_TIMEZONE=UTC
   APP_LOCALE=en
   LOG_LEVEL=warning
   ```

3. **Deploy**
   - Render will automatically deploy both the web service and database
   - The database will be created automatically
   - Environment variables will be linked between services

### Option 2: Manual Deployment

1. **Create Web Service**
   - Go to Render Dashboard
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Set the following:
     - **Name**: snipe-it
     - **Environment**: Docker
     - **Region**: Choose closest to you
     - **Branch**: main
     - **Root Directory**: (leave blank)
     - **Docker Command**: (leave blank)

2. **Create Database**
   - Go to Render Dashboard
   - Click "New +" → "PostgreSQL" or "MySQL"
   - Set the following:
     - **Name**: snipe-it-db
     - **Environment**: Docker
     - **Region**: Same as web service
     - **Database**: snipeit
     - **User**: snipeit

3. **Configure Environment Variables**
   In your web service, add these environment variables:

   ```
   APP_ENV=production
   APP_DEBUG=false
   APP_KEY=base64:your-generated-key
   APP_URL=https://your-app-name.onrender.com
   APP_TIMEZONE=UTC
   APP_LOCALE=en
   DB_CONNECTION=mysql
   DB_HOST=your-db-host
   DB_PORT=5432
   DB_DATABASE=snipeit
   DB_USERNAME=snipeit
   DB_PASSWORD=your-db-password
   MAIL_MAILER=smtp
   MAIL_HOST=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=your-app-password
   MAIL_ENCRYPTION=tls
   MAIL_FROM_ADDRESS=noreply@yourdomain.com
   MAIL_FROM_NAME=Snipe-IT
   IMAGE_LIB=gd
   SESSION_LIFETIME=12000
   EXPIRE_ON_CLOSE=false
   ENCRYPT=false
   COOKIE_NAME=snipeit_session
   SECURE_COOKIES=true
   CACHE_DRIVER=file
   SESSION_DRIVER=file
   QUEUE_DRIVER=sync
   FILESYSTEM_DISK=local
   LOG_CHANNEL=stack
   LOG_LEVEL=warning
   SESSION_SECURE_COOKIE=true
   SESSION_HTTP_ONLY=true
   ```

## Post-Deployment Setup

1. **Access your application**
   - Go to your web service URL
   - You should see the Snipe-IT setup page

2. **Create admin user**
   - Access your application container:
   ```bash
   # Via Render shell or SSH
   docker exec -it your-container-name bash
   ```
   - Run the user creation command:
   ```bash
   php artisan snipeit:create-user
   ```

3. **Verify deployment**
   - Check that all services are running
   - Test the application functionality
   - Verify email sending works

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_KEY` | Laravel application key | `base64:generated-key` |
| `APP_URL` | Your application URL | `https://your-app.onrender.com` |
| `DB_HOST` | Database host | `your-db-host` |
| `DB_DATABASE` | Database name | `snipeit` |
| `DB_USERNAME` | Database username | `snipeit` |
| `DB_PASSWORD` | Database password | `secure-password` |
| `MAIL_HOST` | SMTP server | `smtp.gmail.com` |
| `MAIL_USERNAME` | SMTP username | `your-email@gmail.com` |
| `MAIL_PASSWORD` | SMTP password | `your-app-password` |
| `MAIL_FROM_ADDRESS` | From email address | `noreply@yourdomain.com` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_TIMEZONE` | Application timezone | `UTC` |
| `APP_LOCALE` | Application locale | `en` |
| `LOG_LEVEL` | Logging level | `warning` |
| `SESSION_LIFETIME` | Session lifetime in minutes | `12000` |
| `SECURE_COOKIES` | Enable secure cookies | `true` |

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify database credentials
   - Check if database service is running
   - Ensure network connectivity

2. **Email Not Working**
   - Verify SMTP credentials
   - Check if SMTP service allows external connections
   - Test with a simple email service first

3. **Permission Errors**
   - Check file permissions in storage directory
   - Ensure proper ownership of files

4. **Application Key Issues**
   - Generate a new application key
   - Clear application cache

### Logs

View logs in Render Dashboard:
1. Go to your web service
2. Click on "Logs" tab
3. Check for error messages

### Health Checks

The application includes health checks that will:
- Verify the application is responding
- Check database connectivity
- Monitor resource usage

## Security Considerations

1. **Use strong passwords** for database and admin accounts
2. **Enable HTTPS** (automatic on Render)
3. **Regular backups** of your database
4. **Keep dependencies updated**
5. **Monitor logs** for suspicious activity

## Scaling

Render automatically scales your application based on traffic. You can also:
- Upgrade to a higher plan for more resources
- Add additional services as needed
- Configure custom scaling rules

## Support

If you encounter issues:
1. Check the [Snipe-IT documentation](https://snipe-it.readme.io/docs)
2. Review Render's [deployment guides](https://render.com/docs)
3. Check the application logs for specific error messages
4. Contact Render support for platform-specific issues 