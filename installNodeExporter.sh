#!/usr/bin/env bash
# ============================================================================
#
# Created 2022-11-13 by StarWarsFan
#
# ============================================================================

# Store path from where script was called,
# determine own location and cd there
callDir=$(pwd)
ownLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${ownLocation}

NODE_VERSION=1.5.0

# Determine architecture
if [ $(uname -m) = 'aarch64' ] ; then
    ARCH_SUFFIX="arm64"
else
    ARCH_SUFFIX="amd64"
fi

# Download and extract node exporter archive
cd /usr/src/
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-${ARCH_SUFFIX}.tar.gz
tar xf node_exporter-${NODE_VERSION}.linux-${ARCH_SUFFIX}.tar.gz

# Install binaries, cleanup and create user
mv node_exporter-*/node_exporter /usr/local/bin
rm -rf /usr/src/node_exporter-${NODE_VERSION}.linux-amd64*
adduser -M -r -s /sbin/nologin node_exporter

# Setup node exporter service
cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
