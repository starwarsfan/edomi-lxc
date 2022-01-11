#!/usr/bin/env bash
# ============================================================================
#
# Created 2020-02-10 by StarWarsFan
#
# ============================================================================

# Store path from where script was called,
# determine own location and cd there
callDir=$(pwd)
ownLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${ownLocation}

# Some defaults
EDOMI_VERSION=EDOMI_203.tar
EDOMI_EXTRACT_PATH=/tmp/edomi/
EDOMI_ARCHIVE=/tmp/edomi.tar

# Install what we need ;-)
dnf module enable -y \
    php:7.4
dnf install -y \
    epel-release
dnf update -y
dnf upgrade -y
dnf clean all

dnf install -y \
    ca-certificates \
    chrony \
    dos2unix \
    expect \
    file \
    git \
    hostname \
    httpd \
    mariadb-server \
    mod_ssl \
    mosquitto \
    mosquitto-devel \
    nano \
    net-snmp-utils \
    net-tools \
    nss \
    oathtool \
    openssh-server \
    openssl \
    passwd \
    php \
    php-curl \
    php-gd \
    php-json \
    php-mbstring \
    php-mysqlnd \
    php-process \
    php-snmp \
    php-soap \
    php-xml \
    php-zip \
    python2 \
    tar \
    unzip \
    vsftpd \
    wget \
    dnf-utils
dnf clean all
rm -f /etc/vsftpd/ftpusers \
      /etc/vsftpd/user_list

# Alexa
ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/tls/cacert.pem
sed -i \
    -e '/\[curl\]/ a curl.cainfo = /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem' \
    -e '/\[openssl\] a openssl.cafile = /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem' \
    /etc/php.ini

# Get composer
cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === file_get_contents('https://composer.github.io/installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
mkdir -p /usr/local/edomi/main/include/php

# For Telegram-LBS 19000303 / 19000304
cd /usr/local/edomi/main/include/php
git clone https://github.com/php-telegram-bot/core
mv core php-telegram-bot
cd php-telegram-bot
composer install --no-interaction

# MikroTik RouterOS API 19001059
#cd /usr/local/edomi/main/include/php
#git clone https://github.com/jonofe/Net_RouterOS
#cd Net_RouterOS
#composer install --no-interaction

# Philips HUE Bridge 19000195
# As long as https://github.com/sqmk/Phue/pull/143 is not merged, fix phpunit via sed
cd /usr/local/edomi/main/include/php
git clone https://github.com/sqmk/Phue
cd Phue
sed -i "s/PHPUnit/phpunit/g" composer.json
composer install --no-interaction

# Mailer-LBS 19000587
cd /usr/local/edomi/main/include/php
mkdir PHPMailer
cd PHPMailer
composer require phpmailer/phpmailer --no-interaction

# For Mosquitto-LBS
mkdir -p /usr/lib64/php/modules/
cp ${ownLocation}/php-modules/mosquitto.so /usr/lib64/php/modules/
cp ${ownLocation}/mariadb-plugins/*          /usr/lib64/mariadb/plugin/
chmod +x /usr/lib64/php/modules/mosquitto.so /usr/lib64/mariadb/plugin/lib_mysqludf_*

echo 'extension=mosquitto.so' > /etc/php.d/50-mosquitto.ini

# Alexa Control 19000809
cd /etc/ssl/certs
wget https://curl.haxx.se/ca/cacert.pem -O /etc/ssl/certs/cacert-Mozilla.pem
echo "curl.cainfo=/etc/ssl/certs/cacert-Mozilla.pem" >> /etc/php.d/curl.ini

# Edomi
systemctl enable chronyd
systemctl enable vsftpd
systemctl enable httpd
systemctl enable php-fpm
systemctl enable mariadb

sed -e "s/listen=.*$/listen=YES/g" \
    -e "s/listen_ipv6=.*$/listen_ipv6=NO/g" \
    -e "s/userlist_enable=.*/userlist_enable=NO/g" \
    -i /etc/vsftpd/vsftpd.conf

systemctl start sshd
systemctl enable sshd

localectl set-locale LANG=de_DE.utf8
localectl set-x11-keymap de
localectl set-keymap de-nodeadkeys
timedatectl set-timezone Europe/Berlin

# Get Edomi archive and extract it
wget -O ${EDOMI_ARCHIVE} http://edomi.de/download/install/${EDOMI_VERSION}
mkdir -p ${EDOMI_EXTRACT_PATH}
tar -xf ${EDOMI_ARCHIVE} -C ${EDOMI_EXTRACT_PATH}
cd ${EDOMI_EXTRACT_PATH}

# Modify install script
# - Remove firewall steps
# - Remove SELinux modification
# - Remove Grub modification
# - Remove tty-force from systemd service creation
# - Remove php 7.2 installation as 7.4 is already installed
# - Remove package install steps
# - Add Restart, SuccessExitStatus and ExecStop to systemd service creation
# - Replace default.target with multi-user.target
sed -i \
    -e '/Firewall/d' \
    -e '/firewalld/d' \
    -e '/SELinux/d' \
    -e '/selinux/d' \
    -e '/Bootvorgang/d' \
    -e '/grub/d' \
    -e '/StandardInput=tty-force/d' \
    -e '/install php/d' \
    -e '/rpm -Uvh/d' \
    -e '/remi-/d' \
    -e '/epel-release-/d' \
    -e '/\[Service\]/a echo "Restart=on-success" >> /etc/systemd/system/edomi.service\necho "SuccessExitStatus=SIGHUP" >> /etc/systemd/system/edomi.service' \
    -e '/ExecStart/a echo "ExecStop=/bin/sh /usr/local/edomi/main/stop.sh" >> /etc/systemd/system/edomi.service' \
    -e 's/default\.target/multi-user\.target/g' \
    install.sh

cp ${ownLocation}/scripts/stop.sh /usr/local/edomi/main/stop.sh
chmod +x /usr/local/edomi/main/stop.sh

# Start Edomi installation, choose "2" as install version and accept to install on unknown system
{
   echo "2"
   echo "j"
} | ./install.sh

# Enable lib_mysqludf_sys
systemctl start mariadb
mysql -u root mysql < ${ownLocation}/scripts/installdb.sql
systemctl stop mariadb

# Tweak some default settings
sed -i \
    -e 's#global_serverConsoleInterval=.*#global_serverConsoleInterval=false#' \
    -e "s#global_serverIP=.*#global_serverIP=''#" \
    /usr/local/edomi/edomi.ini
