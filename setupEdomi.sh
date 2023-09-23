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

# Determine architecture
if [ $(uname -m) = 'aarch64' ] ; then
    ARCH_SUFFIX="-aarch64"
fi

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
    mc \
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
    rsync \
    sudo \
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
cd /usr/local/edomi/main/include/php
git clone https://github.com/jonofe/Net_RouterOS
cd Net_RouterOS
composer install --no-interaction

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

# Influx Data Archives 19002576
mkdir -p /usr/local/edomi/www/admin/include/php/influx-client
cd /usr/local/edomi/www/admin/include/php/influx-client
composer require influxdata/influxdb-client-php

# For Mosquitto-LBS
mkdir -p /usr/lib64/php/modules/
cp ${ownLocation}/php-modules${ARCH_SUFFIX}/mosquitto.so /usr/lib64/php/modules/
cp ${ownLocation}/mariadb-plugins${ARCH_SUFFIX}/*        /usr/lib64/mariadb/plugin/
chmod +x /usr/lib64/php/modules/mosquitto.so /usr/lib64/mariadb/plugin/lib_mysqludf_*

echo 'extension=mosquitto.so' > /etc/php.d/50-mosquitto.ini

# Alexa Control 19000809
cd /etc/ssl/certs
wget https://curl.haxx.se/ca/cacert.pem -O /etc/ssl/certs/cacert-Mozilla.pem
echo "curl.cainfo=/etc/ssl/certs/cacert-Mozilla.pem" >> /etc/php.d/curl.ini

# Chrony on LXC container needs some special treatment
# See https://bugs.launchpad.net/ubuntu/+source/chrony/+bug/1589780
sed -i 's/OPTIONS="/OPTIONS="-x /g' /etc/sysconfig/chronyd

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

# Configure mariadb
cat << EOF > /tmp/tmp.txt
key_buffer_size=256M
sort_buffer_size=8M
read_buffer_size=16M
read_rnd_buffer_size=4M
myisam_sort_buffer_size=4M
join_buffer_size=4M
query_cache_limit=8M
query_cache_size=8M
query_cache_type=1
wait_timeout=28800
interactive_timeout=28800
EOF

# STRICT_TRANS_TABLES (strict mode) needs to be disabled, otherwise statements
# like this will fail because of the empty values:
# INSERT INTO edomiProject.editLogicCmdList (targetid,cmd,cmdid1,cmdid2,cmdoption1,cmdoption2,cmdvalue1,cmdvalue2) \
#                                    VALUES ('2',    '1', '101', '',    '',        '',        null,     null)
echo "sql_mode=ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /tmp/tmp.txt

sed -i '/\[mysqld\]/r /tmp/tmp.txt' /etc/my.cnf.d/mariadb-server.cnf

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
# - Remove systemctl disable postfix (not installed)
# - Modify creation of systemd unit script to remove all calls of ntpd from
#   /usr/local/edomi/main/start.sh and create dummy /dev/vcsa right before
#   Edomi start. This is neccessary as a modified start.sh would be replaced
#   by an Edomi update!
# - Add Restart, SuccessExitStatus and ExecStop to systemd service creation
# - Replace default.target with multi-user.target
# - Replace ntpd with chronyd
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
    -e '/postfix/d' \
    -e '/\[Service\]/a echo "Restart=on-success" >> /etc/systemd/system/edomi.service\necho "SuccessExitStatus=SIGHUP" >> /etc/systemd/system/edomi.service' \
    -e '/Type=simple/a echo "ExecStartPre=-sed -i -e \\"/ntpd/d\\" /usr/local/edomi/main/start.sh" >> /etc/systemd/system/edomi.service\necho "ExecStartPre=-sed -i -e \\"s@pkill -9 php.*@pkill -9 -x php@g\\" /usr/local/edomi/main/start.sh" >> /etc/systemd/system/edomi.service\necho "ExecStartPre=-touch /dev/vcsa" >> /etc/systemd/system/edomi.service' \
    -e '/ExecStart/a echo "ExecStop=/bin/sh /usr/local/bin/stop_edomi.sh" >> /etc/systemd/system/edomi.service' \
    -e 's/default\.target/multi-user\.target/g' \
    -e 's/ntpd/chronyd/g' \
    install.sh

cp ${ownLocation}/scripts/stop.sh /usr/local/bin/stop_edomi.sh
chmod +x /usr/local/bin/stop_edomi.sh

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
    -e "s/62\.75\.208\.51/edomi\.de/g" \
    /usr/local/edomi/edomi.ini

# Enable Lynx-like motion on Midnight Commander
mkdir -p /root/.config/mc
cp ${ownLocation}/configurations/.config/mc/* /root/.config/mc/

# Install Prometheus node exporter
${ownLocation}/installNodeExporter.sh
