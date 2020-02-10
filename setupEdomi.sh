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
EDOMI_VERSION=EDOMI_201.tar
ROOT_PASS=123456
EDOMI_EXTRACT_PATH=/tmp/edomi/
EDOMI_ARCHIVE=/tmp/edomi.tar
START_SCRIPT=/root/start.sh
EDOMI_BACKUP_DIR=/var/edomi-backups
EDOMI_DB_DIR=/var/lib/mysql
EDOMI_INSTALL_DIR=/usr/local/edomi

# Install what we need ;-)
yum update -y
yum upgrade -y
yum install -y \
    epel-release
yum update -y
yum install -y \
    ca-certificates \
    file \
    git \
    hostname \
    httpd \
    mariadb-server \
    mc \
    mod_ssl \
    mosquitto \
    mosquitto-devel \
    nano \
    net-tools \
    ntp \
    openssh-server \
    tar \
    unzip \
    vsftpd \
    wget \
    yum-utils
yum install -y \
    http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager \
    --enable remi-php72
yum install -y \
    php \
    php-gd \
    php-mbstring \
    php-mysql \
    php-process \
    php-soap \
    php-ssh2 \
    php-xml \
    php-zip

# Telegram-LBS
cd /tmp
wget --no-check-certificate https://getcomposer.org/installer
php installer
mv composer.phar /usr/local/bin/composer
mkdir -p /usr/local/edomi/main/include/php
cd /usr/local/edomi/main/include/php
git clone https://github.com/php-telegram-bot/core
mv core php-telegram-bot
cd php-telegram-bot
composer install

# Mailer-LBS 19000587
cd /usr/local/edomi/main/include/php/
mkdir PHPMailer
cd PHPMailer
composer require phpmailer/phpmailer

# Mosquitto-LBS
mkdir -p /usr/lib64/php/modules/
cp ${ownLocation}/php-modules/mosquitto.so /usr/lib64/php/modules/
echo 'extension=mosquitto.so' > /etc/php.d/50-mosquitto.ini

# MikroTik-LBS
yum -y update \
    nss
yum clean all
cd /usr/local/edomi/main/include/php
git clone https://github.com/jonofe/Net_RouterOS
cd Net_RouterOS
composer install

# Edomi
systemctl enable ntpd
systemctl enable vsftpd
systemctl enable httpd
systemctl enable mariadb

rm -f /etc/vsftpd/ftpusers \
      /etc/vsftpd/user_list
sed -e "s/listen=.*$/listen=YES/g" \
    -e "s/listen_ipv6=.*$/listen_ipv6=NO/g" \
    -e "s/userlist_enable=.*/userlist_enable=NO/g" \
    -i /etc/vsftpd/vsftpd.conf

# Remove limitation to only one installed language
sed -i "s/override_install_langs=.*$/override_install_langs=all/g" /etc/yum.conf
yum update -y
yum reinstall -y \
    glibc-common
yum clean all

systemctl start sshd
systemctl enable sshd

localectl set-locale LANG=de_DE.utf8
localectl set-x11-keymap de
localectl set-keymap de-nodeadkeys

# Get Edomi archive and extract it
wget -O ${EDOMI_ARCHIVE} http://edomi.de/download/install/${EDOMI_VERSION}
mkdir -p ${EDOMI_EXTRACT_PATH}
tar -xf ${EDOMI_ARCHIVE} -C ${EDOMI_EXTRACT_PATH}
cd ${EDOMI_EXTRACT_PATH}

# Modify install script
sed -i \
    -e '/Firewall/d' \
    -e '/firewalld/d' \
    -e '/SELinux/d' \
    -e '/selinux/d' \
    -e '/Bootvorgang/d' \
    -e '/grub/d' \
    -e '/StandardInput=tty-force/d' \
    -e '/Conflicts=getty/a echo "Restart=on-success" >> /etc/systemd/system/edomi.service\necho "SuccessExitStatus=SIGHUP" >> /etc/systemd/system/edomi.service' \
    install.sh

echo 7 | ./install.sh
