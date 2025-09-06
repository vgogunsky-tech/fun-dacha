FROM php:8.1-apache

# Install required libraries for GD and other extensions
RUN apt-get update && apt-get install -y \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install mysqli zip gd \
    && a2enmod rewrite

WORKDIR /var/www/html

# Download and extract the latest OpenCart
RUN curl -s https://api.github.com/repos/opencart/opencart/releases/latest \
    | grep "browser_download_url.*zip" \
    | cut -d '"' -f4 \
    | xargs curl -L -o opencart.zip \
    && unzip opencart.zip -d /tmp/opencart \
    && cp -r /tmp/opencart/upload/* /var/www/html/ \
    && rm -rf /tmp/opencart opencart.zip

RUN cp config-dist.php config.php \
    && cp admin/config-dist.php admin/config.php

RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod 666 /var/www/html/config.php \
    && chmod 666 /var/www/html/admin/config.php

EXPOSE 80

