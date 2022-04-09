#!/usr/bin/env bash
# ============================================================================
#
# Created 2020-02-11 by StarWarsFan
#
# ============================================================================

echo -n "Prepare current system to create a LXC template? y/N: "
read input
if [[ "${input}" = "y" ]] || [[ "${input}" = "Y" ]] ; then
    echo "Cleanup dnf (yum) cache"
    dnf clean all

    echo "Removing /etc/resolv.conf"
    rm -f /etc/resolv.conf

    echo "Removing /etc/hostname"
    rm -f /etc/hostname
else
    echo "Skipping system cleanup"
fi
