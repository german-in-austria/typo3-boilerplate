# Docker image for TYPO3 CMS
# Copyright (C) 2016-2020  Martin Helmich <martin@helmich.me>
#                          and contributors <https://github.com/martin-helmich/docker-typo3/graphs/contributors>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# THIS VERSION IS CUSTOMIZED TO ALLOW FOR DEPLOYMENT ON THE "GERMAN IN AUSTRIA" SERVER ENVIRONMENT.

FROM php:7.4-apache-buster
LABEL maintainer="Martin Helmich <typo3@martin-helmich.de>"

# Install TYPO3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
# Configure PHP
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        zlib1g-dev \
# Install required 3rd party tools
        sendmail \
        graphicsmagick \
        ghostscript && \
# Configure extensions
    docker-php-ext-configure gd --with-libdir=/usr/include/ --with-jpeg --with-freetype && \
    docker-php-ext-install -j$(nproc) mysqli soap gd zip opcache intl pgsql pdo_pgsql && \
    echo 'always_populate_raw_post_data = -1\nmax_execution_time = 240\nmax_input_vars = 1500\nupload_max_filesize = 128M\npost_max_size = 128M\ndate.timezone = Europe/Berlin' > /usr/local/etc/php/conf.d/typo3.ini && \
# Configure Apache as needed
    a2enmod rewrite && \
    apt-get clean && \
    apt-get -y purge \
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* /usr/src/*

RUN cd /var/www/html && \
    wget -O download.tar.gz https://get.typo3.org/10.4.17 && \
    echo "05a9f6352b2506b2a3446d0e8d18cefb7ed5e25c0ee5f1aff80ccf68fdc775c6 download.tar.gz" > download.tar.gz.sum && \
    sha256sum -c download.tar.gz.sum && \
    tar -xzf download.tar.gz && \
    rm download.* && \
    ln -s typo3_src-* typo3_src && \
    ln -s typo3_src/index.php && \
    ln -s typo3_src/typo3 && \
    cp typo3/sysext/install/Resources/Private/FolderStructureTemplateFiles/root-htaccess .htaccess && \
    mkdir typo3temp && \
    mkdir typo3conf && \
    mkdir fileadmin && \
    mkdir uploads && \
    # touch FIRST_INSTALL && \
    chown -R www-data. .

# WARNING, DANGER, ATTENTION:
# THIS MIGHT BREAK, IF SWIFTMAILER EVER GETS UPDATED.
COPY ./\TransportFactory.php /var/www/html/typo3_src-10.4.17/typo3/sysext/core/Classes/Mail/TransportFactory.php

# LOGGING
RUN echo "error_log = /var/log/php-scripts.log\nlog_errors = On" >> /usr/local/etc/php/conf.d/typo3.ini

# Configure volumes
VOLUME /var/www/html/fileadmin
VOLUME /var/www/html/typo3conf
VOLUME /var/www/html/typo3temp
VOLUME /var/www/html/uploads
