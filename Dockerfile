FROM debian:jessie
MAINTAINER Larry Price <larry@larry-price.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install git -y --force-yes
RUN apt-get install postgresql -y --force-yes
RUN apt-get install sendmail sendmail-bin -y --force-yes
RUN apt-get install wkhtmltopdf -y --force-yes
RUN apt-get install supervisor -y --force-yes
RUN apt-get install apache2 -y --force-yes
RUN apt-get install libapache2-mod-php5 -y --force-yes
RUN apt-get install php5-pgsql -y --force-yes

RUN service postgresql start

RUN git clone https://github.com/francoisjacquet/rosariosis.git /usr/src/rosariosis

RUN rm -rf /var/www/html && mkdir -p /var/www && ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html

ADD bin/init /init
ADD bin/start-apache2 /start-apache2
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD conf/config.inc.php /usr/src/rosariosis/config.inc.php

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

ENTRYPOINT [ "/init" ]
