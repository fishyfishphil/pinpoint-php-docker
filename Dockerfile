FROM php:7.2-fpm

#########################
# DISTRO UPDATES
#########################

RUN apt-get update \
    && apt-get install -yq \
        wget \
        zlib1g-dev \
        telnet \
        jq \
        wget \
        zlib1g-dev \
        telnet \
        vim \
        rsyslog-gnutls \
        supervisor \
        gnupg


#########################
# PHP DEPENDENCIES
#########################

# RUN docker-php-ext-install \
#         mysqli \
#         zip \
#         pdo_mysql \
#         sockets \
#         opcache


#########################
# COMPOSER INSTALL
#########################
COPY composer.phar /var/www/
WORKDIR /var/www
# RUN php /var/www/composer.phar global require hirak/prestissimo
# RUN php /var/www/composer.phar install --no-scripts --no-dev
# RUN php -d memory_limit=-1 /var/www/composer.phar require giggsey/libphonenumber-for-php --no-scripts


###########################
# PINPOINT AGENT SETUP
###########################

RUN echo "Installing dependencies for pinpoint"
RUN apt-get update \
    && apt-get install -yq \
        python3 \
        python3-venv \
        python3-pip

ADD ./pinpoint-c-agent /pinpoint-c-agent

RUN echo "Build pinpoint-php-module"
WORKDIR /pinpoint-c-agent/PHP/pinpoint_php_ext
RUN phpize
RUN ./configure
RUN make
RUN make install
COPY pinpoint-c-agent/PHP/pinpoint_php_ext/php.ini.example /usr/local/etc/php/php.ini

RUN echo "Build Collect-agent"
WORKDIR /pinpoint-c-agent/collector-agent
RUN python3 -m venv env
RUN /bin/bash -c "source env/bin/activate"
RUN pip3 install -r requirements.txt

RUN mkdir /pinpoint-logs
COPY collector.conf /pinpoint-c-agent/collector-agent/conf/collector.conf
ENV COLLECTOR_CONFIG /pinpoint-c-agent/collector-agent/conf/collector.conf

RUN pip3 install grpcio-tools
RUN python3 -m grpc_tools.protoc -I./Proto/grpc --python_out=./Proto/grpc --grpc_python_out=./Proto/grpc ./Proto/grpc/*.proto
# RUN python3 run.py

