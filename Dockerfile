FROM php:8.3-fpm-alpine

# Instalar dependencias del sistema y herramientas de compilación
RUN apk add --no-cache \
    nginx \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    icu-dev \
    oniguruma-dev \
    linux-headers \
    sqlite-dev \
    libxml2-dev \
    $PHPIZE_DEPS

# Instalar extensiones de PHP (Agrupadas para optimizar el build)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo \
    pdo_sqlite \
    mbstring \
    zip \
    exif \
    pcntl \
    bcmath \
    intl \
    opcache

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiar archivos de dependencias primero (aprovechar caché de Docker)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader

# Copiar el resto del código
COPY . .

# Finalizar instalación de composer
RUN composer dump-autoload --optimize

# Permisos para SQLite y Laravel
RUN mkdir -p storage/database \
    && touch storage/database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 8000

CMD php artisan config:clear && php artisan serve --host=0.0.0.0 --port=8000