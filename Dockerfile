# Dockerfile for RosarioSIS
# https://www.rosariosis.org/
# Best Dockerfile practices: http://crosbymichael.com/dockerfile-best-practices.html

FROM php:7.0-apache

LABEL maintainer="François Jacquet <francoisjacquet@users.noreply.github.com>"

ENV PGHOST=rosariosisdb \
    PGUSER=postgres \
    PGPASSWORD=postgres \
    PGDATABASE=postgres \
    PGPORT=5432 \
    ROSARIOSIS_YEAR=2018 \
    ROSARIOSIS_LANG='en_US'

# Upgrade packages.
# Install git, Apache2 + PHP + PostgreSQL webserver, sendmail, wkhtmltopdf & others utilities.

# Change date to force an upgrade:
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install postgresql-client wkhtmltopdf libpq-dev libpng-dev libxml2-dev sendmail -y;

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-install -j$(nproc) gd mbstring xml pgsql gettext xmlrpc

# Download and extract rosariosis
ENV ROSARIOSIS_VERSION 'v4.3.2'
RUN mkdir /usr/src/rosariosis && \
    curl -L https://gitlab.com/francoisjacquet/rosariosis/-/archive/${ROSARIOSIS_VERSION}/rosariosis-${ROSARIOSIS_VERSION}.tar.gz \
    | tar xz --strip-components=1 -C /usr/src/rosariosis && \
    rm -rf /var/www/html && mkdir -p /var/www && \
    ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html &&\
    chown -R www-data:www-data /usr/src/rosariosis

# Copy our custom RosarioSIS configuration file.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php
COPY conf/.htaccess /usr/src/rosariosis/.htaccess
COPY bin/init /init


EXPOSE 80

ENTRYPOINT ["/init"]
CMD ["apache2-foreground"]
