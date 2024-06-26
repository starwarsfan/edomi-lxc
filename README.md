# Edomi-LXC

This is an LXC template containing Edomi, a PHP-based smarthome framework.

For more information please refer to [Official website](http://www.edomi.de/) or [Support forum](https://knx-user-forum.de/forum/projektforen/edomi)

## Create container from template

### Install template

1. Download the [latest release](https://github.com/starwarsfan/edomi-lxc/releases/latest) according to the architecture of your ProxMox installation
1. On ProxMox
   1. Select desired storage
   1. Select type `CT Templates`
   1. Click `Upload`
   1. Click `Select File`
   1. Select the previously downloaded archive
   1. Upload it

### Create container from template

1. Click `Create CT`
2. Fill 1st page as you like. Usage of `Unprivileged container` and `Nesting` is fine.
3. On 2nd page (`Template`) select used storage and choose previously uploaded template
4. Fill the following pages (Disc, Memory, CPU, Network) according to your needs

The container is now ready to run and Edomi will be available using `http://<ip>/admin`.

It might be neccessary to set the timezone according to your location:

```bash
timedatectl set-timezone Europe/Berlin
```

## Build own template

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
5. Start the setup script
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
   * Notes:
     * `Edomi AMD64 LXC Template`
     * `Edomi ARMv8 LXC Template`

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
   lvdisplay | grep <container-id>   # Search LV path of container
   mkdir /mnt/edomi-arm-container
   mount <LV-Path> /mnt/edomi-arm-container
   cp qemu-aarch64-static /mnt/edomi-arm-container/usr/bin/
   chmod 755 /mnt/edomi-arm-container/usr/bin/qemu-aarch64-static
   chown 100000:100000 /mnt/edomi-arm-container/usr/bin/qemu-aarch64-static
   umount /mnt/edomi-arm-container
   ```
