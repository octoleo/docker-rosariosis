FROM ubuntu
MAINTAINER Larry Price <larry@larry-price.com>

ENV DEBIAN_FRONTEND noninteractive

RUN /usr/bin/lsb_release -a
RUN apt-get update && apt-get install git sendmail sendmail-bin supervisor apache2 libjpeg-turbo8-dev fontconfig \
                                      libapache2-mod-php5 php5-pgsql php5-curl php5-xmlrpc xfonts-75dpi openssl build-essential \
                                      xorg libssl-dev wget telnet nmap -y --force-yes
RUN wget http://downloads.sourceforge.net/wkhtmltopdf/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
RUN dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
RUN cp -f /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf

RUN git clone https://github.com/francoisjacquet/rosariosis.git /usr/src/rosariosis
WORKDIR /usr/src/rosariosis
RUN git checkout v2.8.12

RUN rm -rf /var/www/html && mkdir -p /var/www && ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html

COPY bin/init /init
COPY bin/start-apache2 /start-apache2
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

ENTRYPOINT [ "/init" ]
