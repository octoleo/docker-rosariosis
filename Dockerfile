# Dockerfile for RosarioSIS
# https://www.rosariosis.org/
# Best Dockerfile practices: http://crosbymichael.com/dockerfile-best-practices.html

# https://hub.docker.com/_/php?tab=tags&page=1&name=apache
FROM php:7.3-apache

LABEL maintainer="François Jacquet <francoisjacquet@users.noreply.github.com>"

ENV PGHOST=db \
    PGUSER=rosario \
    PGPASSWORD=rosariopwd \
    PGDATABASE=rosariosis \
    PGPORT=5432 \
    ROSARIOSIS_YEAR=2019 \
    ROSARIOSIS_LANG='en_US'

# Upgrade packages.
# Install git, Apache2 + PHP + PostgreSQL webserver, sendmail, wkhtmltopdf & others utilities.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install postgresql-client wkhtmltopdf libpq-dev libpng-dev libxml2-dev sendmail -y;

# Install PHP extensions.
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-install -j$(nproc) gd mbstring xml pgsql gettext xmlrpc

# Download and extract rosariosis
ENV ROSARIOSIS_VERSION 'v5.2'
RUN mkdir /usr/src/rosariosis && \
    curl -L https://gitlab.com/francoisjacquet/rosariosis/-/archive/${ROSARIOSIS_VERSION}/rosariosis-${ROSARIOSIS_VERSION}.tar.gz \
    | tar xz --strip-components=1 -C /usr/src/rosariosis && \
    rm -rf /var/www/html && mkdir -p /var/www && \
    ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html &&\
    chown -R www-data:www-data /usr/src/rosariosis

# Copy our configuration files.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php
COPY conf/.htaccess /usr/src/rosariosis/.htaccess
COPY bin/init /init

EXPOSE 80

ENTRYPOINT ["/init"]
CMD ["apache2-foreground"]
