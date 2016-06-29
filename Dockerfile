# Dockerfile for RosarioSIS
# https://www.rosariosis.org/
# Best Dockerfile practices: http://crosbymichael.com/dockerfile-best-practices.html

FROM ubuntu

MAINTAINER François Jacquet <info@rosariosis.org>

ENV DEBIAN_FRONTEND noninteractive

# Release info.
RUN /usr/bin/lsb_release -a

# Upgrade packages.
# Add universe depot.
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list

# Change date to force an upgrade:
RUN apt-get update # 2016-06-29
RUN apt-get upgrade -y

# Install git, Apache2 + PHP + PostgreSQL webserver, sendmail, wkhtmltopdf & others utilities.
RUN apt-get install git postgresql sendmail sendmail-bin wkhtmltopdf supervisor apache2 \
                    libapache2-mod-php php-pgsql php-curl php-xmlrpc \
                    openssl wget telnet nmap -y --force-yes

RUN git clone https://github.com/francoisjacquet/rosariosis.git /usr/src/rosariosis
WORKDIR /usr/src/rosariosis

# Uncomment to checkout a tagged release:
# RUN git checkout 2.9.3

# Links rosariosis directory to Apache document root.
RUN rm -rf /var/www/html && mkdir -p /var/www && ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html

# Copy our init script (creates rosariosis PostgreSQL DB & import rosariosis.sql file).
COPY bin/init /init

# Copy our start Apache2 script.
COPY bin/start-apache2 /start-apache2

# Copy our custom supervisord.conf file.
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy our custom RosarioSIS configuration file.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

ENTRYPOINT [ "/init" ]
