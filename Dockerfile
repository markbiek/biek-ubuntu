# Borrowed heavily from https://github.com/tutumcloud/lamp
FROM ubuntu:16.10
MAINTAINER Mark Biek (support@janustech.net)

ENV DEBIAN_FRONTEND noninteractive

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Install packages
RUN apt-get update && \
    apt-get install --fix-missing -y sudo apache2 curl apt-utils build-essential bzip2 dos2unix elinks git gnupg gzip mysql-common mysql-server npm openssh-client openssh-server p7zip php php-pdo php-mysql php-zip php-mbstring php-dom php-sybase python tmux supervisor zip vim pwgen

# Create our initial mount-point for external data
RUN mkdir /opt/data

# Create setup script directory
RUN mkdir -p /opt/scripts

# Configuration scripts
ADD start-apache2.sh    /opt/scripts/start-apache2.sh
ADD start-mysqld.sh     /opt/scripts/start-mysqld.sh
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
RUN mkdir -p /var/log/supervisor

# Apache2 config
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite headers ssl

# MySQL config
ADD create_mysql_admin_user.sh /opt/scripts/create_mysql_admin_user.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf

# Misc config
ADD run.sh /opt/scripts/run.sh
RUN chmod 755 /opt/scripts/*.sh

# Install dev tools
# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash - && \
    apt-get install -y nodejs

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer

# Install Laravel
RUN composer global require "laravel/installer"
RUN echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> /root/.bashrc

# Laravel example
COPY example.tar.gz /example.tar.gz
RUN tar xzvf /example.tar.gz -C /var/www && \
    rm /example.tar.gz
ADD example.conf /etc/apache2/sites-available

EXPOSE 80
CMD ["/opt/scripts/run.sh"]
