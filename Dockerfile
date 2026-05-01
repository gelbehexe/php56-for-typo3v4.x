FROM php:5.6-fpm-stretch
LABEL authors="gelbehexe"

COPY conf/apt/sources.list /etc/apt/sources.list
COPY conf/apt/no-check-valid-until /etc/apt/apt.conf.d/99no-check-valid-until

RUN apt-get update && apt-get install -y \
    unzip \
    graphicsmagick \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    msmtp \
    procps \
    default-mysql-client-core \
    tidy \
    && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysql mbstring \
    && rm -rf /var/lib/apt/lists/*
#
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY conf/typo3.ini /usr/local/etc/php/conf.d/typo3.ini
COPY files/msmtprc.template /etc/msmtprc.template
COPY files/entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["php-fpm"]
