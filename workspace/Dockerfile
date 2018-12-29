# ---------------------------------------
# Builder for caching dependencies
# ---------------------------------------

FROM php:7.3-cli-stretch AS cache

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    unzip \
    git && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer global require hirak/prestissimo

RUN curl -sSL http://cs.sensiolabs.org/download/php-cs-fixer-v2.phar -o /usr/local/bin/php-cs-fixer && \
    chmod +x /usr/local/bin/php-cs-fixer

WORKDIR /repo

COPY . .

RUN composer --version && composer install -o --prefer-dist --no-ansi --no-interaction --ignore-platform-reqs

# have ";true" since we want the build to complete even if there is stuff to fix
RUN php-cs-fixer fix --dry-run --diff --diff-format udiff --no-ansi --no-interaction; true

# --------------------------
# Image for building the workspace
# --------------------------

FROM php:7.3-cli-stretch

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

# install extra utils
RUN curl -sSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    echo "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") jessie stable" >> /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    nano \
    links \
    less \
    psmisc \
    man \
    mysql-client \
    unzip \
    supervisor \
    git \
    python-pip \
    python-dev \
    jq \
    libyaml-dev \
    openssh-client \
    docker-ce && \
    rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade setuptools
RUN pip install awscli --upgrade
RUN curl -sSL https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN curl -sSL https://raw.githubusercontent.com/silinternational/ecs-deploy/develop/ecs-deploy -o /usr/local/bin/ecs-deploy && \
    chmod +x /usr/local/bin/ecs-deploy
COPY --from=cache /usr/local/bin/composer /usr/local/bin/composer
COPY --from=cache /usr/local/bin/php-cs-fixer /usr/local/bin/php-cs-fixer

COPY docker/workspace/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY --from=cache /root/.composer /workspace-image-cached/.composer
ENV COMPOSER_HOME /workspace-image-cached/.composer

# COPY --from=cache /repo/.php_cs.cache /workspace-image-cached/.php_cs.cache

# since the container will run under different UID:GID depending on env (jenkins vs locally)
# we need to make /workspace globally writable
RUN chmod -R 777 /workspace-image-cached

# install php ini
COPY docker/workspace/php.ini /usr/local/etc/php/conf.d/tgtg.ini

