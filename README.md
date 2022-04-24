## Edomi-LXC

This is an LXC template containing Edomi, a PHP-based smarthome framework.

For more information please refer to [Official website](http://www.edomi.de/) or [Support forum](https://knx-user-forum.de/forum/projektforen/edomi)

### Configure container

1. Create container from [RockyLinux template](https://uk.lxd.images.canonical.com/images/rockylinux/)
2. ARMv8: See [Additional steps for ARMv8 on x86_64 host](#additional-steps-for-armv8-on-x86_64-host)
3. Install ssh and git
   ```bash
   dnf update -y
   dnf install -y openssh-server git
   systemctl enable sshd
   systemctl start sshd
   ```
4. Clone this Git repository to `/root/edomi-lxc/`
   ```bash
   cd /root/
   git clone https://github.com/starwarsfan/edomi-lxc
   ```
5. Make setup script executable and start it
   ```bash
   cd /root/edomi-lxc
   ./setupEdomi.sh
   ```
Now Edomi is installed and will be started with the next reboot.

### Prepare template
If setup is finished, the system can be prepared using the script
```bash
./prepareTemplate.sh
```

This script will cleanup the dnf (yum) package cache and remove `/etc/resolv.conf`
as well as `/etc/hostname`. You can shutdown the system afterwards to go
ahead with the template creation steps.

### Create template
After the container is powered off, perform these steps on the Proxmox
web ui:
1. Remove all network devices from the container
2. Create backup of container with
   * Mode: Stop
   * Compression: GZip

Now login to the ProxMox host using `ssh`. You will find the template archive
afterwards on the ProxMox host at `/var/lib/vz/dump/vzdump-lxc-<id>-<iso-timestamp>.tar.gz`.
To use it as a template right on this system, the archive needs to be moved
to another location:
```bash
cd /var/lib/vz
mv dump/vzdump-lxc-<id>-<iso-timestamp>.tar.gz template/cache/my-edomi-template.tar.gz
```
After this step the template will be available during container creation
using ProxMox web ui.

### Additional steps for ARMv8 on x86_64 host
1. Do not start the container!
2. Package `qemu-user-static` must be installed on host
3. Copy `qemu-aarch64-static` into container filesystem and fix ownership/permission:
   ```bash
   lvdisplay    # Search LV path of container
   mkdir /mnt/edomi-arm-container
   mount <LV-Path> /mnt/edomi-arm-container
   cp qemu-aarch64-static /mnt/edomi-arm-container/usr/bin/
   chmod 755 /mnt/edomi-arm-container/usr/bin/qemu-aarch64-static
   chown 100000:100000 /mnt/edomi-arm-container/usr/bin/qemu-aarch64-static
   ```
