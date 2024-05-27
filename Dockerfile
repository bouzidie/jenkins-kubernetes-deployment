FROM php:7.4-apache

ARG PHP_TIMEZONE
ARG PHP_ENABLE_UPLOADS
ARG PHP_MEMORY_LIMIT
ARG PHP_POST_MAX_SIZE
ARG PHP_UPLOAD_MAX_FILESIZE
ARG PHP_MAX_FILE_UPLOADS
ARG PHP_MAX_INPUT_TIME
ARG PHP_LOG_ERRORS
ARG PHP_ERROR_REPORTING

RUN set -x \
 && runtimeDeps="libfreetype6 libjpeg62-turbo" \
 && buildDeps="libpng-dev libjpeg-dev libfreetype6-dev" \
 && apt-get update && apt-get install -y ${buildDeps} ${runtimeDeps} --no-install-recommends \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

RUN set -x \
 && buildDeps="libldap2-dev" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install ldap \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

RUN set -x \
 && runtimeDeps="libicu67" \
 && buildDeps="libicu-dev" \
 && apt-get update && apt-get install -y ${buildDeps} ${runtimeDeps} --no-install-recommends \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

RUN set -x \
 && docker-php-ext-install mysqli

RUN set -x \
 && apt-get update && apt-get install -y graphviz --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

RUN set -x \
 && runtimeDeps="" \
 && buildDeps="libxml2-dev" \
 && apt-get update && apt-get install -y ${buildDeps} ${runtimeDeps} --no-install-recommends \
 && docker-php-ext-install soap \
 && docker-php-ext-install opcache \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

RUN set -x \
 && runtimeDeps="libzip-dev zlib1g-dev" \
 && apt-get update && apt-get install -y ${runtimeDeps} --no-install-recommends \
 && docker-php-ext-configure zip \
 && docker-php-ext-install zip \
 && rm -rf /var/lib/apt/lists/*

ARG APP_NAME="itop"
WORKDIR /var/www/$APP_NAME

ARG ITOP_VERSION=2.7.6
ARG ITOP_PATCH=8526
RUN set -x \
 && buildDeps="libarchive-tools" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 && curl -sL https://sourceforge.net/projects/itop/files/itop/$ITOP_VERSION/iTop-$ITOP_VERSION-$ITOP_PATCH.zip \
  | bsdtar --strip-components=1 -xf- web \
 && chmod -R 777 /var/www/$APP_NAME \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

RUN { \
  echo "<VirtualHost *:80>"; \
  echo "DocumentRoot /var/www/$APP_NAME"; \
  echo; \
  echo "<Directory /var/www/$APP_NAME>"; \
  echo "\tOptions -Indexes"; \
  echo "\tAllowOverride all"; \
  echo "\tRequire all granted"; \
  echo "</Directory>"; \
  echo "</VirtualHost>"; \
 } | tee "$APACHE_CONFDIR/sites-available/$APP_NAME.conf" \
 && set -x \
 && a2dissite 000-default \
 && a2ensite $APP_NAME \
 && a2enmod headers \
 && echo "ServerName $APP_NAME" >> $APACHE_CONFDIR/apache2.conf

RUN { \
  echo 'ServerTokens Prod'; \
  echo 'ServerSignature Off'; \
  echo 'TraceEnable Off'; \
  echo 'Header set X-Content-Type-Options "nosniff"'; \
  echo 'Header set X-Frame-Options "sameorigin"'; \
 } | tee $APACHE_CONFDIR/conf-available/security.conf \
 && set -x \
 && a2enconf security

ENV PHP_TIMEZONE=${PHP_TIMEZONE} \
    PHP_ENABLE_UPLOADS=${PHP_ENABLE_UPLOADS} \
    PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT} \
    PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE} \
    PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE} \
    PHP_MAX_FILE_UPLOADS=${PHP_MAX_FILE_UPLOADS} \
    PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME} \
    PHP_LOG_ERRORS=${PHP_LOG_ERRORS} \
    PHP_ERROR_REPORTING=${PHP_ERROR_REPORTING}

EXPOSE 22 80 443

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT [ "docker-entrypoint" ]

CMD [ "apache2-foreground" ]
