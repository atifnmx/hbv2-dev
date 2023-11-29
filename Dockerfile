FROM php:8.2-apache

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    unzip \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql

RUN a2enmod rewrite

COPY composer.json composer.lock ./
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install --optimize-autoloader --no-scripts # purposely remove the --no-dev flag as nunomaduro/collision is causing the issue.

COPY . .

# Set ownership and permissions
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

RUN mv .env.prod .env

#RUN php artisan key:generate

#RUN php artisan migrate --force

# Clear cache and other Laravel clear commands
RUN php artisan config:clear
RUN php artisan route:clear
RUN php artisan view:clear
RUN php artisan cache:clear
RUN php artisan optimize

# Define the virtual host configuration
RUN echo "<VirtualHost *:80>\n\
    ServerName localhost\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Order Allow,Deny\n\
        Allow from All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
#COPY apache.conf /etc/apache2/sites-available/000-default.conf

ENV APP_ENV=prod

EXPOSE 80

# Set up the entrypoint command
CMD ["apache2-foreground"]
