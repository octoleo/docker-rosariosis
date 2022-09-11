#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#


FROM php:7.4-apache
LABEL maintainer="François Jacquet <francoisjacquet@users.noreply.github.com> (@francoisjacquet), Llewellyn van der Merwe <Llewellynvdm@users.noreply.github.com> (@Llewellynvdm)"

# Disable remote database security requirements.
ENV ROSARIOSIS_INSTALLATION_DISABLE_LOCALHOST_CHECK=1
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# To be able to send mail
		sendmail \
		nano \
		locales \
	; \
	rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need.
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libbz2-dev \
		libxml2-dev \
		libgmp-dev \
		libicu-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libldap2-dev \
		libmemcached-dev \
		wkhtmltopdf \
		libpq-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
		libonig-dev \
		postgresql-client \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg \
		--with-webp \
	; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
	docker-php-ext-install -j "$(nproc)" \
		bz2 \
		bcmath \
		exif \
		gd \
		mbstring \
		xml \
		xmlrpc \
		gmp \
		intl \
		ldap \
		mysqli \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		gettext \
		zip \
	; \
	\
# some misbehaving extensions end up outputting to stdout
	out="$(php -r 'exit(0);')"; \
	[ -z "$out" ]; \
	err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]; \
	\
	extDir="$(php -r 'echo ini_get("extension_dir");')"; \
	[ -d "$extDir" ]; \
# pecl will claim success even if one install fails, so we need to perform each install separately
	pecl install APCu-5.1.21; \
	pecl install memcached-3.2.0; \
	\
	docker-php-ext-enable \
		apcu \
		memcached \
	; \
	[ -d /tmp/pear ] && rm -r /tmp/pear; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$extDir"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
	! { ldd "$extDir"/*.so | grep 'not found'; }; \
# check for output like "PHP Warning:  PHP Startup: Unable to load dynamic library 'foo' (tried: ...)
	err="$(php --version 3>&1 1>&2 2>&3)"; \
	[ -z "$err" ]

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
	docker-php-ext-enable opcache; \
	{ \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# set recommended error logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

RUN set -eux; \
	a2enmod rewrite expires; \
	\
# https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html
	a2enmod remoteip; \
	{ \
		echo 'RemoteIPHeader X-Forwarded-For'; \
# these IP ranges are reserved for "private" use and should thus *usually* be safe inside Docker
		echo 'RemoteIPTrustedProxy 10.0.0.0/8'; \
		echo 'RemoteIPTrustedProxy 172.16.0.0/12'; \
		echo 'RemoteIPTrustedProxy 192.168.0.0/16'; \
		echo 'RemoteIPTrustedProxy 169.254.0.0/16'; \
		echo 'RemoteIPTrustedProxy 127.0.0.0/8'; \
	} > /etc/apache2/conf-available/remoteip.conf; \
	a2enconf remoteip; \
# (replace all instances of "%h" with "%a" in LogFormat)
	find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

VOLUME /var/www/html

# Define Rosariosis version and expected SHA512 signature
ENV ROSARIOSIS_VERSION 10.2
ENV ROSARIOSIS_SHA512 ffc49aac888c39670d8b30a362c5e8becf71abccd26cd72a7e0392adfd67b6887c2ee365490c4cfd0fad8b87f00ff27573e18d99f530e2d131515894ef044c96

# Download package and extract to web volume
RUN set -ex; \
	curl -o rosariosis.tar.bz2 -SL https://gitlab.com/francoisjacquet/rosariosis/-/archive/v10.2/rosariosis-v10.2.tar.bz2; \
	echo "$ROSARIOSIS_SHA512 *rosariosis.tar.bz2" | sha512sum -c -; \
	mkdir -p /usr/src/rosariosis; \
	tar -xf rosariosis.tar.bz2 --strip-components=1 -C /usr/src/rosariosis; \
	rm rosariosis.tar.bz2; \
	chown -R www-data:www-data /usr/src/rosariosis

# Copy init scripts
COPY conf/docker-entrypoint.sh /entrypoint.sh
# Copy our configuration files.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php
COPY conf/htaccess.txt /usr/src/rosariosis/.htaccess

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

