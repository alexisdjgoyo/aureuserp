FROM php:8.3-fpm-alpine

# Instalar dependencias del sistema y extensiones de PHP necesarias para Laravel y SQLite
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
    $PHPIZE_DEPS

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_sqlite mbstring zip exif pcntl bcmath intl

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar directorio de trabajo
WORKDIR /var/www/html

# Copiar el código del proyecto (tu fork)
COPY . .

# Instalar dependencias de Composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Crear el archivo de base de datos SQLite preventivamente y dar permisos
RUN mkdir -p storage/database \
    && touch storage/database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer el puerto que usará Dokploy
EXPOSE 8000

# Script de arranque para limpiar caché y levantar el servidor
CMD php artisan config:clear && php artisan serve --host=0.0.0.0 --port=8000