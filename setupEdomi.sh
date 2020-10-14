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
EDOMI_VERSION=EDOMI_202.tar
EDOMI_EXTRACT_PATH=/tmp/edomi/
EDOMI_ARCHIVE=/tmp/edomi.tar

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
    htop \
    httpd \
    mariadb-server \
    mc \
    mod_ssl \
    mosquitto \
    mosquitto-devel \
    nano \
    net-snmp-utils \
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
    php-curl \
    php-gd \
    php-mbstring \
    php-mysql \
    php-process \
    php-soap \
    php-snmp \
    php-ssh2 \
    php-xml \
    php-zip

# For Telegram-LBS
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

# For Mailer-LBS 19000587
cd /usr/local/edomi/main/include/php/
mkdir PHPMailer
cd PHPMailer
composer require phpmailer/phpmailer

# For Mosquitto-LBS
mkdir -p /usr/lib64/php/modules/
cp ${ownLocation}/php-modules/mosquitto.so /usr/lib64/php/modules/
cp ${ownLocation}/mysql-modules/*          /usr/lib64/mysql/plugin/
chmod +x /usr/lib64/mysql/plugin/lib_mysqludf_*

echo 'extension=mosquitto.so' > /etc/php.d/50-mosquitto.ini

# For MikroTik-LBS
yum -y update \
    nss
yum clean all
cd /usr/local/edomi/main/include/php
git clone https://github.com/jonofe/Net_RouterOS
cd Net_RouterOS
composer install

# Philips HUE-LBS
cd /usr/local/edomi/main/include/php
git clone https://github.com/sqmk/Phue
cd Phue
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
# - Add Restart, SuccessExitStatus and ExecStop to systemd service creation
sed -i \
    -e '/Firewall/d' \
    -e '/firewalld/d' \
    -e '/SELinux/d' \
    -e '/selinux/d' \
    -e '/Bootvorgang/d' \
    -e '/grub/d' \
    -e '/StandardInput=tty-force/d' \
    -e '/Conflicts=getty/a echo "Restart=on-success" >> /etc/systemd/system/edomi.service\necho "SuccessExitStatus=SIGHUP" >> /etc/systemd/system/edomi.service' \
    -e '/ExecStart/a echo "ExecStop=/bin/sh /usr/local/edomi/main/stop.sh" >> /etc/systemd/system/edomi.service' \
    install.sh

cp ${ownLocation}/scripts/stop.sh /usr/local/edomi/main/stop.sh
chmod +x /usr/local/edomi/main/stop.sh

# Start Edomi installation and choose "7" as install version
echo 7 | ./install.sh

# Enable lib_mysqludf_sys
systemctl start mariadb
mysql -u root mysql < ${ownLocation}/scripts/lib_mysqludf_sys.sql
systemctl stop mariadb

# Tweak some default settings
sed -i \
    -e 's#global_serverConsoleInterval=.*#global_serverConsoleInterval=false#' \
    /usr/local/edomi/edomi.ini
