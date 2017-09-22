# Dockerfile for RosarioSIS
# https://www.rosariosis.org/
# Best Dockerfile practices: http://crosbymichael.com/dockerfile-best-practices.html

FROM php:5.6-apache

MAINTAINER François Jacquet <francoisjacquet@users.noreply.github.com>

# Upgrade packages.
# Change date to force an upgrade:
RUN apt-get update # 2016-06-29
RUN apt-get upgrade -y

# Install git, Apache2 + PHP + PostgreSQL webserver, sendmail, wkhtmltopdf & others utilities.
RUN apt-get install postgresql-client wkhtmltopdf libpq-dev libpng-dev libxml2-dev sendmail -y;

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
docker-php-ext-install -j$(nproc) gd mbstring xml pgsql gettext xmlrpc

RUN mkdir /usr/src/rosariosis && curl -L https://github.com/francoisjacquet/rosariosis/tarball/v3.5 | tar xz --strip-components=1 -C /usr/src/rosariosis

WORKDIR /usr/src/rosariosis

RUN rm -rf /var/www/html && mkdir -p /var/www && \
    ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html &&\
    chown -R www-data:www-data /usr/src/rosariosis


# Uncomment to checkout a tagged release:
# RUN git checkout 2.9.3

# Copy our custom RosarioSIS configuration file.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php
COPY conf/.htaccess /usr/src/rosariosis/.htaccess
COPY bin/init /init


EXPOSE 80

ENTRYPOINT ["/init"]
CMD ["apache2-foreground"]
