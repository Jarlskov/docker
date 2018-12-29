FROM php:7.3-fpm-stretch

# install php extension
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    libxml2-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libxrender1 \
    libfontconfig \
    libxext6 \
    gnupg2 \
    ca-certificates \
    apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install exif
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install opcache
RUN docker-php-ext-install soap
RUN docker-php-ext-install sockets
RUN docker-php-ext-install curl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install intl
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install bcmath

# copy content
COPY ./ /var/www/html
COPY docker/fpm/php.ini /usr/local/etc/php/conf.d/website.ini

CMD ["docker/fpm/cmd.bash"]
