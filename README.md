## Edomi-LXC

This is an LXC template containing Edomi, a PHP-based smarthome framework.

For more information please refer to [Official website](http://www.edomi.de/) or [Support forum](https://knx-user-forum.de/forum/projektforen/edomi)

### Configure container

1. Create container from CentOS 7 template
2. Install ssh
   ```
   yum install -y openssh-server
   systemctl enable sshd
   systemctl start sshd
   ```
3. Copy the whole content of this Git repository to `/root/edomi/`
4. Make setup script executable and start it
   ```
   cd /root/edomi
   chmod +x setupEdomi.sh
   ./setupEdomi.sh
   ```
