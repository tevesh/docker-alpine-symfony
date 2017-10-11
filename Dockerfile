FROM alpine:edge

# ENV VARIABLES
ENV PROJECT_PATH=/var/www/app \
    DEBIAN_FRONTEND=noninteractive \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    PHP_INI=/etc/php7/php.ini \
    TERM=xterm

# INSTALL SERVER UTILS
RUN apk --update --no-cache add curl musl nano zip

# INSTALL APACHE2
RUN apk --update --no-cache add apache2 apache2-utils

#INSTALL DEV UTILS
RUN apk --update --no-cache add git

# INSTALL PHP7
RUN apk --update --no-cache add php7 \
php7-apache2 \
php7-cli \
php7-ctype \
php7-curl \
php7-dom \
php7-json \
php7-iconv \
php7-mbstring \
php7-memcached \
php7-mcrypt \
php7-mysqli \
php7-openssl \
php7-phar \
php7-pdo \
php7-pdo_mysql \
php7-tokenizer \
php7-xml \
php7-zlib

# INSTALL NPM
#RUN apk --update --no-cache add nodejs-npm \
#yarn

# CREATE SIMLINK TO CALL NODEJS AS NODE
#RUN ln -s "$(which node)" /usr/bin/nodejs

RUN curl -sS https://getcomposer.org/installer | php7 -- --install-dir=/usr/local/bin --filename=composer

# CLEAN CACHE AFTER INSTALLATION
RUN rm -f /var/cache/apk/*

# USEFULL TO RUN APACHE
RUN mkdir /run/apache2 && chown -R apache:apache /run/apache2
RUN mkdir /var/www/app && chown -R apache:apache /var/www/app
RUN mkdir /etc/apache2/vhost.d && chown -R apache:apache /etc/apache2/vhost.d

# USEFULL TO RUN MYSQL
#RUN mkdir -p /var/lib/mysql && chown -R apache:apache /var/lib/mysql && \
#    mkdir -p /etc/mysql/conf.d && chown -R apache:apache /etc/mysql/conf.d && \
#    mkdir -p /var/run/mysql && chown -R apache:apache /var/run/mysql

# CREATE LINK FOR LOGS
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log

#RUN sed -i 's#AllowOverride none#AllowOverride All#' /etc/apache2/httpd.conf && \
# APACHE CONFIG
#RUN sed -i 's#^DocumentRoot ".*#DocumentRoot "$PROJECT_PATH"#g' /etc/apache2/httpd.conf && \
#    sed -i "s/#ServerName\ www.example.com:80.*$/ServerName localhost/" /etc/apache2/httpd.conf && \
#    sed -i "s/#LoadModule rewrite_module modules\/mod_rewrite.so.*$/LoadModule rewrite_module modules\/mod_rewrite.so/" /etc/apache2/httpd.conf && \
#    sed -i "s/#LoadModule headers_module modules\/mod_headers.so.*$/LoadModule headers_module modules\/mod_headers.so/" /etc/apache2/httpd.conf && \
#    sed -i "s/#LoadModule expires_module modules\/mod_expires.so.*$/LoadModule expires_module modules\/mod_expires.so/" /etc/apache2/httpd.conf

# APACHE CONFIG
RUN sed -i 's/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/' /etc/apache2/httpd.conf && \
sed -i 's/#LoadModule\ expires_module/LoadModule\ expires_module/' /etc/apache2/httpd.conf && \
sed -i 's/#LoadModule\ mod_headers/LoadModule\ mod_headers/' /etc/apache2/httpd.conf && \
sed -i "s#^DocumentRoot \".*#DocumentRoot \"/var/www/app\"#g" /etc/apache2/httpd.conf && \
sed -i 's#AllowOverride none#AllowOverride All#' /etc/apache2/httpd.conf && \
sed -i "s#/var/www/localhost/htdocs#$PROJECT_PATH#" /etc/apache2/httpd.conf && \
sed -i "s/#ServerName\ www.example.com:80.*$/ServerName localhost/" /etc/apache2/httpd.conf

# PHP CONFIG
RUN sed -i "s/short_open_tag = .*/short_open_tag = On/" $PHP_INI && \
    sed -i "s/memory_limit = .*/memory_limit = 256M/" $PHP_INI && \
    sed -i "s/display_errors = .*/display_errors = On/" $PHP_INI && \
    sed -i "s/display_startup_errors = .*/display_startup_errors = On/" $PHP_INI && \
    sed -i "s/post_max_size = .*/post_max_size = 64M/" $PHP_INI && \
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 32M/" $PHP_INI && \
    sed -i "s/max_file_uploads = .*/max_file_uploads = 10/" $PHP_INI && \
    sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/" $PHP_INI

# ADDITIONAL PHP CONFIG
#RUN sed -i -e "\$a ; Enable ctype extension module" $PHP_INI && \
#    sed -i -e "\$a extension = ctype.so" $PHP_INI

ADD scripts/run.sh /scripts/run.sh
RUN mkdir /scripts/pre-exec.d && \
mkdir /scripts/pre-init.d

RUN chmod -R 755 /scripts

# INCLUDE VIRTUAL HOST
ADD config/docker/apache-virtualhost.conf /etc/apache2/conf.d/httpd-vhosts.conf

EXPOSE 80 443

WORKDIR $PROJECT_PATH

# NPM install
#ADD package.json ./package.json
#RUN npm config set loglevel warn
#RUN npm install --quiet --production

# Bower install
#ADD bower.json ./bower.json
#ADD .bowerrc ./.bowerrc
#RUN $(npm bin -q)/bower install --allow-root --quiet

ENTRYPOINT ["/scripts/run.sh"]