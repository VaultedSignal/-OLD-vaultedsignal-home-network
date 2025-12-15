# Proxmox VE Initial Setup & Hardening

Complete post-installation configuration and security hardening guide for Proxmox Virtual Environment.

## Overview

This guide covers the essential steps after installing Proxmox VE, including repository configuration, network setup, user management, and comprehensive security hardening. Following these steps will create a secure, production-ready virtualization platform.

## Why Harden Proxmox?

- 🎯 **High-Value Target**: Hypervisors control all virtual machines
- 🔓 **Default Settings**: Out-of-the-box configs prioritize convenience over security
- 🌐 **Network Exposure**: Management interfaces are network-accessible
- 👑 **Root Access**: Default root login provides full system control
- 🛡️ **Defense Layers**: Multiple security measures protect critical infrastructure

## Technology Stack

- **Hypervisor**: Proxmox Virtual Environment (PVE)
- **Base OS**: Debian-based Linux
- **Web Interface**: Port 8006 (HTTPS)
- **Firewall**: UFW (Uncomplicated Firewall)
- **Intrusion Prevention**: Fail2Ban
- **Authentication**: Optional 2FA/TOTP support

## Initial Setup Checklist

- [ ] Proxmox VE installed
- [ ] Console/physical access available
- [ ] Network connectivity established
- [ ] Root password known
- [ ] Repository configuration completed
- [ ] System fully updated
- [ ] Hostname and network configured
- [ ] Administrative user created
- [ ] Firewall rules applied
- [ ] Fail2Ban configured
- [ ] Root web access disabled
- [ ] Documentation updated

## Part 1: Initial Configuration

### Access Proxmox Web Interface

After installation, access the web interface:

**URL**: `https://proxmox-ip:8006`

**Default Credentials**:

- Username: `root`
- Password: Set during installation
- Realm: `Linux PAM standard authentication`

### Configure Repositories

Remove enterprise repositories and enable no-subscription updates:

#### Via Web Interface (Recommended)

1. Navigate to **Datacenter** > **Node** > **Updates** > **Repositories**
2. **Disable** these repositories:
   - `pve-enterprise` (Enterprise subscription required)
   - `ceph-enterprise` (If shown)
3. **Add** the no-subscription repository if not present:
   - Click **Add**
   - Select **No-Subscription**

#### Via Command Line

```bash
# Disable enterprise repository
echo "# deb https://enterprise.proxmox.com/debian/pve $(lsb_release -sc) pve-enterprise" | sudo tee /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repository
echo "deb http://download.proxmox.com/debian/pve $(lsb_release -sc) pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-no-subscription.list

# For Ceph (if using)
echo "# deb https://enterprise.proxmox.com/debian/ceph-quincy $(lsb_release -sc) enterprise" | sudo tee /etc/apt/sources.list.d/ceph.list
```

### Update System

Apply all available updates:

#### Via Web Interface

1. Navigate to **Updates**
2. Click **Refresh** to update package lists
3. Review available updates
4. Click **Upgrade** to install updates

#### Via Command Line

```bash
# Update package lists
apt update

# Upgrade all packages
apt full-upgrade -y

# Clean up
apt autoremove -y
apt autoclean
```

### Upload ISO Images

Prepare installation media for VMs:

1. Navigate to **Datacenter** > **Storage** > **local**
2. Select **ISO Images**
3. Click **Upload** or **Download from URL**
4. Upload your OS installation ISOs

**Common ISOs to have**:

- Ubuntu Server (latest LTS)
- Debian (latest stable)
- Windows Server (if licensed)
- Alpine Linux (lightweight)

## Part 2: Network Configuration

### Change Hostname

Set a descriptive hostname for your Proxmox server:

```bash
# Edit hostname file
nano /etc/hostname
```

Replace content with your desired hostname (e.g., `proxmox-01`, `stargatecommand`):

```text
stargatecommand
```

**Update hosts file**:

```bash
nano /etc/hosts
```

Update the line with your hostname:

```text
127.0.0.1       localhost
192.168.1.10    stargatecommand.local stargatecommand

# IPv6 entries
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

**Apply changes**:

```bash
# Reboot to apply hostname changes
reboot
```

### Configure Static IP Address

Set a static IP for reliable management access:

```bash
# Edit network configuration
nano /etc/network/interfaces
```

**Example configuration**:

```ini
# Loopback interface
auto lo
iface lo inet loopback

# Physical network interface (adjust name as needed)
iface eno1 inet manual

# Bridge for VMs (vmbr0)
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24      # Static IP and subnet mask
    gateway 192.168.1.1           # Router/gateway IP
    bridge-ports eno1             # Physical interface
    bridge-stp off                # Disable spanning tree
    bridge-fd 0                   # Forward delay

# Additional bridges can be added as needed
# auto vmbr1
# iface vmbr1 inet static
#     address 10.0.0.1/24
#     bridge-ports none
#     bridge-stp off
#     bridge-fd 0

source /etc/network/interfaces.d/*
```

**Important notes**:

- Replace `eno1` with your actual network interface name (check with `ip link`)
- Use `/24` for subnet mask 255.255.255.0
- Gateway should be your router's IP address

### Configure DNS Servers

Set reliable DNS servers:

```bash
# Edit resolver configuration
nano /etc/resolv.conf
```

**Example DNS configuration**:

```ini
# Cloudflare DNS
nameserver 1.1.1.1
nameserver 1.0.0.1

# Or Google DNS
# nameserver 8.8.8.8
# nameserver 8.8.4.4

# Or your router
# nameserver 192.168.1.1

# Or Pi-hole (if installed)
# nameserver 192.168.1.999
```

### Apply Network Changes

```bash
# Restart networking service
systemctl restart networking

# Or reboot for full network reset
reboot
```

**Verify connectivity**:

```bash
# Check IP configuration
ip addr show

# Test internet connectivity
ping -c 4 1.1.1.1

# Test DNS resolution
ping -c 4 google.com
```

## Part 3: User Management & Security

### Create Administrative User

Create a non-root user for daily administration:

#### Via Web Interface

1. Navigate to **Datacenter** > **Permissions** > **Users**
2. Click **Add**
3. Fill in details:
   - **User name**: `admin` (or your preferred username)
   - **Realm**: `Proxmox VE authentication server`
   - **Password**: Set strong password
   - **Email**: Your email address
4. Click **Add**

**Grant Administrator Role**:

1. Navigate to **Datacenter** > **Permissions**
2. Click **Add** > **User Permission**
3. Configure:
   - **Path**: `/` (root, entire datacenter)
   - **User**: Select your new user
   - **Role**: `Administrator`
4. Click **Add**

### Enable Command Line Access for User

Allow the new user to use SSH and sudo:

```bash
# Create home directory
mkdir -p /home/admin
chown admin:admin /home/admin
chmod 700 /home/admin

# Set shell to bash
usermod -s /bin/bash admin

# Install sudo if not present
apt update && apt install sudo -y

# Add user to sudo group
usermod -aG sudo admin

# Test sudo access
su - admin
sudo whoami
# Should output: root
```

### Enable Two-Factor Authentication (Optional but Recommended)

Add an extra security layer with TOTP:

1. **Generate Recovery Keys** (Save these securely!):
   - Navigate to **Datacenter** > **Permissions** > **Two Factor**
   - Select your user
   - Click **Add** > **Recovery Keys**
   - Download and store keys in a safe location

2. **Add TOTP**:
   - Click **Add** > **TOTP**
   - Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
   - Enter verification code
   - Click **Add**

3. **Test 2FA**:
   - Log out of web interface
   - Log in with username, password, and TOTP code

### Disable Root Web Interface Login

Prevent direct root access via web interface:

1. Navigate to **Datacenter** > **Permissions** > **Users**
2. Select **root@pam**
3. Click **Edit**
4. **Uncheck** `Enabled`
5. Click **OK**

**Important**: Ensure your administrative user has full access before disabling root!

### Disable "No Valid Subscription" Popup

Remove the persistent subscription notification:

```bash
# Navigate to JavaScript directory
cd /usr/share/javascript/proxmox-widget-toolkit

# Backup original file
cp proxmoxlib.js proxmoxlib.js.bak

# Edit the file
nano proxmoxlib.js
```

**Find this section** (around line 500, use Ctrl+W to search for "No valid subscription"):

```javascript
if (res === null || res === undefined || !res || res
    .data.status.toLowerCase() !== 'active') {
    Ext.Msg.show({
        title: gettext('No valid subscription'),
```

**Replace the entire `Ext.Msg.show({` block with**:

```javascript
if (res === null || res === undefined || !res || res
    .data.status.toLowerCase() !== 'active') {
    void({ // Original code commented out
        title: gettext('No valid subscription'),
```

Or simply comment out the entire `Ext.Msg.show` block.

**Alternative method** (easier):

```bash
# Use sed to comment out the notification
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid subscription)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

**Apply changes**:

```bash
# Restart Proxmox web service
systemctl restart pveproxy

# Or fully shutdown and restart
shutdown -r now
```

**Clear browser cache** after restart to see changes.

## Part 4: Firewall Configuration

### UFW (Uncomplicated Firewall) Setup

Restrict management access to local network only:

```bash
# Install UFW if not present
apt install ufw -y

# Set default policies (deny all incoming, allow outgoing)
ufw default deny incoming
ufw default allow outgoing

# Allow SSH from local network only
ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# Allow Proxmox web interface from local network only
ufw allow from 192.168.1.0/24 to any port 8006 proto tcp

# Explicitly deny SSH from everywhere else (optional, already covered by default deny)
ufw deny 22/tcp

# Enable UFW
ufw enable

# Verify configuration
ufw status verbose
```

**Expected output**:

```txt
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.1.0/24
8006/tcp                   ALLOW IN    192.168.1.0/24
22/tcp                     DENY IN     Anywhere
```

### Advanced UFW Rules

Additional rules for specific services:

```bash
# Allow VNC console access from local network (ports 5900-5999)
ufw allow from 192.168.1.0/24 to any port 5900:5999 proto tcp

# Allow SPICE console access from local network (port 3128)
ufw allow from 192.168.1.0/24 to any port 3128 proto tcp

# Allow migration traffic between Proxmox nodes (if clustered)
# ufw allow from 192.168.1.11 to any port 60000:60050 proto tcp

# Allow Ceph traffic (if using Ceph storage)
# ufw allow from 192.168.1.0/24 to any port 6789 proto tcp
# ufw allow from 192.168.1.0/24 to any port 6800:7300 proto tcp
```

### Proxmox Built-in Firewall (Alternative/Additional)

Proxmox has its own firewall that can be enabled:

#### Via Web Interface

1. Navigate to **Datacenter** > **Firewall** > **Options**
2. Enable **Firewall** at datacenter level
3. Navigate to **Datacenter** > **Firewall** > **Security Group**
4. Create security groups for different purposes
5. Navigate to **Node** > **Firewall** to configure node-specific rules

#### Basic Firewall Rules

```bash
# Edit firewall config
nano /etc/pve/firewall/cluster.fw
```

Add rules:

```ini
[OPTIONS]
enable: 1

[RULES]
# Allow SSH from local network
IN ACCEPT -source 192.168.1.0/24 -dport 22 -proto tcp

# Allow Proxmox web interface from local network
IN ACCEPT -source 192.168.1.0/24 -dport 8006 -proto tcp

# Drop all other incoming
IN DROP
```

## Part 5: Fail2Ban Configuration

### Install Fail2Ban

```bash
# Install Fail2Ban
apt install fail2ban -y

# Enable and start service
systemctl enable --now fail2ban
```

### Configure Fail2Ban for Proxmox

```bash
# Create local configuration
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit local configuration
nano /etc/fail2ban/jail.local
```

**Configure default settings**:

```ini
[DEFAULT]
# Whitelist your local network
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24

# Ban duration
bantime = 1h

# Time window to count failures
findtime = 10m

# Number of failures before ban
maxretry = 3
```

**Add Proxmox-specific jail**:

```ini
[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 1h
findtime = 10m
```

**Create Proxmox filter**:

```bash
nano /etc/fail2ban/filter.d/proxmox.conf
```

Add:

```ini
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
```

### Restart and Verify Fail2Ban

```bash
# Restart Fail2Ban
systemctl restart fail2ban

# Check status
systemctl status fail2ban

# Verify jails are active
fail2ban-client status

# Check Proxmox jail specifically
fail2ban-client status proxmox
```

## Verification & Testing

### Test Administrative User

```bash
# SSH as new user
ssh admin@proxmox-ip

# Test sudo access
sudo pvesh get /version

# Access web interface
# Navigate to https://proxmox-ip:8006
# Log in as admin@pve
```

### Test Security Measures

```bash
# Verify UFW is active
sudo ufw status

# Check Fail2Ban jails
sudo fail2ban-client status

# Review firewall logs
sudo tail -f /var/log/ufw.log

# Review Fail2Ban logs
sudo tail -f /var/log/fail2ban.log

# Check for failed login attempts
sudo grep "authentication failure" /var/log/daemon.log | tail -20
```

### Performance Check

```bash
# Check system resources
pvesh get /nodes/$(hostname)/status

# View running VMs/containers
pvesh get /cluster/resources --type vm

# Check storage
pvesh get /nodes/$(hostname)/storage
```

## Maintenance

### Regular Updates

```bash
# Update Proxmox (via web interface)
# Navigate to Updates > Refresh > Upgrade

# Or via command line
apt update && apt full-upgrade -y
```

### Monitor Logs

```bash
# View system journal
journalctl -xe

# View Proxmox logs
tail -f /var/log/daemon.log

# View authentication logs
tail -f /var/log/auth.log

# View UFW logs
tail -f /var/log/ufw.log
```

### Backup Configuration

```bash
# Backup network config
cp /etc/network/interfaces /root/interfaces.backup

# Backup Proxmox config
tar -czf /root/pve-config-backup-$(date +%Y%m%d).tar.gz /etc/pve/

# Backup firewall rules
ufw status verbose > /root/ufw-rules-$(date +%Y%m%d).txt
```

## Troubleshooting

**Cannot access web interface after firewall setup?**

- Ensure you're connecting from allowed network (192.168.1.0/24)
- Check UFW rules: `sudo ufw status`
- Temporarily disable UFW to test: `sudo ufw disable`

**Locked out after disabling root?**

- Access console directly (physical or IPMI)
- Re-enable root: `pveum user modify root@pam --enable 1`
- Or use administrative user created earlier

**Subscription popup still showing?**

- Clear browser cache completely
- Restart pveproxy: `systemctl restart pveproxy`
- Verify edit was saved: `cat /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js | grep "No valid subscription"`

**Network connectivity issues after IP change?**

- Verify gateway is correct in /etc/network/interfaces
- Check physical link: `ip link show`
- Restart networking: `systemctl restart networking`

**Fail2Ban not banning?**

- Check filter path: `/etc/fail2ban/filter.d/proxmox.conf`
- Verify log path is correct: `/var/log/daemon.log`
- Test filter: `fail2ban-regex /var/log/daemon.log /etc/fail2ban/filter.d/proxmox.conf`

## Best Practices

1. **Always keep a console session open** when making network/firewall changes
2. **Test new user access** before disabling root
3. **Document all changes** including IP addresses and credentials
4. **Regular backups** of VM configurations and data
5. **Monitor logs** for suspicious activity
6. **Keep system updated** with regular patches
7. **Use strong passwords** and enable 2FA
8. **Restrict network access** to management interfaces
9. **Implement proper backup strategy** for VMs and containers
10. **Test disaster recovery** procedures regularly

## Security Checklist

- [ ] Non-subscription repositories configured
- [ ] System fully updated
- [ ] Hostname changed and configured
- [ ] Static IP address set
- [ ] DNS servers configured
- [ ] Administrative user created with full permissions
- [ ] Command line access enabled for admin user
- [ ] Two-factor authentication enabled
- [ ] Root web interface login disabled
- [ ] Subscription popup disabled
- [ ] UFW firewall enabled and configured
- [ ] Fail2Ban installed and configured
- [ ] Local network whitelisted in Fail2Ban
- [ ] SSH hardening applied (see SSH Hardening guide)
- [ ] All tests passed
- [ ] Documentation updated
- [ ] Backup procedures established

## Next Steps

After completing this setup:

1. **Deploy SSH hardening** (see SSH Hardening guide)
2. **Create storage** (local, NFS, Ceph, etc.)
3. **Set up backup schedule** using Proxmox Backup Server or vzdump
4. **Create VM templates** for quick deployment
5. **Configure high availability** (if clustering)
6. **Implement monitoring** with Prometheus/Grafana
7. **Set up off-site backups** for disaster recovery

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox Wiki](https://pve.proxmox.com/wiki/Main_Page)
- [Proxmox Forum](https://forum.proxmox.com/)
- [Proxmox No-Subscription Repository](https://pve.proxmox.com/wiki/Package_Repositories)
- [Debian Security Guide](https://www.debian.org/doc/manuals/securing-debian-manual/)

---

*Part of the SGC Home Network infrastructure project*
