# VM 101: Midway Station - Management & Jump Server

Primary entry point for network access, management server, and Docker host for infrastructure services.

## Overview

Midway Station serves as the central management and jump server for the SGC Home Network infrastructure. It provides secure SSH access to other VMs, hosts Portainer for Docker management across multiple hosts, and acts as the single point of entry for administrative tasks.

## Purpose & Role

- 🚪 **Jump Server**: Single point of entry for SSH access to all other VMs
- 🐳 **Docker Host**: Runs Portainer for centralized container management
- 🔐 **Security Gateway**: Enforces controlled access to infrastructure
- 🎯 **Management Hub**: Central location for administrative tasks
- 📊 **Monitoring Base**: Can host monitoring and logging services

## VM Specifications

### Hardware Configuration

| Component | Specification | Notes |
|-----------|---------------|-------|
| **VM ID** | 101 | |
| **Hostname** | midway-station | |
| **vCPU** | 2 cores | 1 socket, host CPU type |
| **Memory** | 4 GB (4096 MB) | Sufficient for jump server + Portainer |
| **Disk** | 32 GB | OS and Docker volumes |
| **Network** | vmbr0 | Default bridge |
| **OS** | Ubuntu Server LTS | Latest stable release |

### Proxmox VM Settings

#### General

- **VM ID**: 101
- **Name**: midway-station
- **Resource Pool**: Infrastructure (optional)

#### System

- **Machine Type**: q35
- **BIOS**: SeaBIOS
- **SCSI Controller**: VirtIO SCSI single
- **Qemu Agent**: Enabled

#### Disks

- **Bus**: SCSI0
- **Size**: 32 GB
- **Cache**: Write through
- **Discard**: ✓ Enabled (important for SSD)
- **SSD Emulation**: ✓ Enabled (if on SSD storage)

#### CPU

- **Sockets**: 1
- **Cores**: 2
- **Type**: host (maximum performance)

#### Memory

- **Memory**: 4096 MB (4 GB)
- **Ballooning**: Enabled

#### Network

- **Bridge**: vmbr0
- **Model**: VirtIO (paravirtualized)
- **Firewall**: Optional

#### Options

- **Start at boot**: ✓ Yes
- **Start/Shutdown order**: 2
- **Startup delay**: 0 seconds
- **Shutdown timeout**: 60 seconds

**Startup Sequence Rationale**:

- **Order 1**: Prometheus (DNS/Pi-hole) - Must start first for name resolution
- **Order 2**: Midway Station (Jump server) - Starts after DNS is available
- **Order 3+**: Other VMs - Can access Midway Station for management

## Installation

### Ubuntu Server Installation

Follow the standard Ubuntu Server installation process:

1. **Language Selection**: English
2. **Keyboard Layout**: English (US) or your preference
3. **Network Configuration**: Accept DHCP (will configure static IP post-install)
4. **Proxy Configuration**: Leave blank
5. **Mirror Configuration**: Use default Ubuntu archive
6. **Storage Configuration**: Use entire disk, LVM setup
7. **Profile Setup**:
   - **Your name**: Your full name
   - **Server name**: `midway-station`
   - **Username**: Your admin username
   - **Password**: Strong password (store securely)
8. **Ubuntu Pro**: Skip (not needed for home lab)
9. **SSH Setup**: Leave unchecked (will configure manually with hardening)
10. **Featured Server Snaps**: Leave all unchecked
11. **Installation Complete**: Reboot when prompted

**Post-Installation**:

- In Proxmox, stop the VM
- Remove the ISO from the CD/DVD drive
- Start the VM

## Post-Installation Configuration

### Initial System Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential utilities
sudo apt install -y \
    vim \
    htop \
    net-tools \
    curl \
    wget \
    git \
    screen \
    tmux \
    ncdu \
    tree

# Clean up
sudo apt clean
sudo apt autoremove -y
sudo apt autoclean
```

### Disable Root Login

```bash
# Check if root is already locked
sudo passwd -S root

# Lock root account
sudo passwd -l root

# Verify root is locked (should show "root L")
sudo passwd -S root
```

### Create Directory Structure

```bash
# Create Docker directory structure
sudo mkdir -p /docker/portainer
sudo mkdir -p /docker/composefiles

# Create general directories
sudo mkdir -p /backups
sudo mkdir -p /scripts

# Set ownership
sudo chown -R $USER:$USER /docker
sudo chown -R $USER:$USER /backups
sudo chown -R $USER:$USER /scripts
```

## Network Configuration

### Configure Static IP with Netplan

```bash
# Identify network interface
ip addr show

# Backup original configuration
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak

# Edit netplan configuration
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Network Configuration**:

```yaml
network:
  version: 2
  ethernets:
    ens18:  # Replace with your interface name
      dhcp4: no
      addresses:
        - 192.168.1.50/24  # Midway Station static IP
      routes:
        - to: default
          via: 192.168.1.1  # Gateway (router)
      nameservers:
        addresses:
          - 192.168.1.999   # Prometheus (Pi-hole)
          - 1.1.1.1         # Cloudflare DNS (fallback)
          - 1.0.0.1         # Cloudflare DNS (fallback)
```

**Apply configuration**:

```bash
# Test configuration (will auto-revert in 120s if you lose connection)
sudo netplan try

# If successful, press Enter to accept
# Or apply directly
sudo netplan apply

# Verify configuration
ip addr show
ping -c 4 1.1.1.1
ping -c 4 google.com
```

### Configure DNS Resolution

```bash
# Verify DNS configuration
resolvectl status

# Test DNS resolution
nslookup google.com
nslookup google.com 192.168.1.999  # Test Pi-hole specifically
```

## Security Hardening

### UFW Firewall Configuration

Allow SSH only from local network:

```bash
# Install UFW
sudo apt install ufw -y

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from local network only
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# Allow Portainer web interface from local network
sudo ufw allow from 192.168.1.0/24 to any port 9443 proto tcp

# Explicitly deny SSH from everywhere else
sudo ufw deny 22/tcp

# Enable firewall
sudo ufw enable

# Verify configuration
sudo ufw status verbose
```

**Expected output**:

```txt
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.1.0/24
9443/tcp                   ALLOW IN    192.168.1.0/24
22/tcp                     DENY IN     Anywhere
```

### SSH Hardening

Configure SSH for maximum security:

```bash
# Backup SSH configuration
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edit SSH configuration
sudo nano /etc/ssh/sshd_config
```

**Recommended SSH settings**:

```ssh-config
# Basic security
PermitRootLogin no
PasswordAuthentication yes  # Change to 'no' after SSH keys are set up
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 5

# Timeout settings
ClientAliveInterval 300
ClientAliveCountMax 2

# Additional security
X11Forwarding no
AllowAgentForwarding yes  # Useful for jump server
AllowTcpForwarding yes    # Useful for jump server
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Banner
Banner /etc/ssh/ssh_banner

# Restrict to specific users (optional)
# AllowUsers your-username

# Use strong ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
```

**Create SSH banner**:

```bash
sudo nano /etc/ssh/ssh_banner
```

Add:

```txt
*****************************************************************
*                                                               *
*  MIDWAY STATION - AUTHORIZED ACCESS ONLY                     *
*                                                               *
*  This system is the entry point to SGC infrastructure.       *
*  All connections are monitored and logged.                   *
*                                                               *
*  Unauthorized access is strictly prohibited.                 *
*                                                               *
*****************************************************************
```

**Apply SSH configuration**:

```bash
# Test configuration
sudo sshd -t

# Restart SSH service
sudo systemctl restart ssh

# Verify service is running
sudo systemctl status ssh
```

### Fail2Ban Configuration

```bash
# Install Fail2Ban
sudo apt install fail2ban -y

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit configuration
sudo nano /etc/fail2ban/jail.local
```

**Add to [DEFAULT] section**:

```ini
[DEFAULT]
# Whitelist local network and localhost
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24

# Ban settings
bantime = 1h
findtime = 10m
maxretry = 3

# Email notifications (optional)
destemail = admin@example.com
sendername = Fail2Ban-MidwayStation
action = %(action_)s
```

**Enable SSH jail**:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
findtime = 10m
```

**Start and verify Fail2Ban**:

```bash
# Enable and start service
sudo systemctl enable --now fail2ban

# Check status
sudo systemctl status fail2ban

# Verify jails are active
sudo fail2ban-client status

# Check SSH jail
sudo fail2ban-client status sshd
```

## Docker Installation

Install Docker Engine for container management:

```bash
# Add Docker's official GPG key
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**References**:

- [Docker Installation Guide](../docker-engine-installation.md)
- [Official Docker Docs](https://docs.docker.com/engine/install/ubuntu/)

## Portainer Installation

Deploy Portainer for Docker management:

```bash
# Create Portainer directory
mkdir -p /docker/portainer

# Navigate to directory
cd /docker/portainer

# Create docker-compose.yml
nano docker-compose.yml
```

**Portainer compose configuration**:

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - 9443:9443
    volumes:
      - /docker/portainer/data:/data
      - /var/run/docker.sock:/var/run/docker.sock
```

**Deploy Portainer**:

```bash
# Start Portainer
docker compose up -d

# Verify container is running
docker ps

# View logs
docker logs portainer
```

**Access Portainer**:

- URL: `https://192.168.1.50:9443`
- Create admin account on first access
- Set up local Docker environment

**References**:

- [Portainer Installation Guide](../portainer-docker-management.md)
- [Official Portainer Docs](https://docs.portainer.io/)

## SSH Jump Host Configuration

### Configure SSH Client (Your Laptop/Workstation)

Create SSH config file for easy jump host access:

**Windows**: `C:\Users\YourUser\.ssh\config`
**Linux/macOS**: `~/.ssh/config`

```ssh-config
# Midway Station - Jump Server
Host midway
    HostName 192.168.1.50
    User your-username
    IdentityFile ~/.ssh/midway/midway

# Access other VMs through jump host
Host atlantis
    HostName 192.168.1.102
    User admin
    ProxyJump midway
    IdentityFile ~/.ssh/atlantis/atlantis

Host orion
    HostName 192.168.1.103
    User admin
    ProxyJump midway
    IdentityFile ~/.ssh/orion/orion

Host prometheus
    HostName 192.168.1.999
    User admin
    ProxyJump midway
    IdentityFile ~/.ssh/prometheus/prometheus
```

**Usage**:

```bash
# Connect to Midway Station
ssh midway

# Connect to other VMs (automatically uses jump host)
ssh atlantis
ssh orion
ssh prometheus
```

### Generate SSH Keys for Jump Host

```bash
# On your local machine
mkdir -p ~/.ssh/midway
ssh-keygen -t ed25519 -C "midway-station" -f ~/.ssh/midway/midway

# Copy public key to Midway Station
ssh-copy-id -i ~/.ssh/midway/midway.pub username@192.168.1.50

# Test connection
ssh -i ~/.ssh/midway/midway username@192.168.1.50
```

## Services & Access

### Accessible Services

| Service | Port | Protocol | Purpose | Access |
|---------|------|----------|---------|--------|
| SSH | 22 | TCP | Remote shell access | Local network only |
| Portainer | 9443 | TCP | Docker management | Local network only |

### Service URLs

- **Portainer**: `https://192.168.1.50:9443`
- **SSH**: `ssh username@192.168.1.50`

## Monitoring & Maintenance

### System Monitoring

```bash
# View system resources
htop

# Check disk usage
df -h
ncdu /

# View running containers
docker ps

# Check Docker disk usage
docker system df

# View system logs
journalctl -xe
sudo tail -f /var/log/syslog
```

### Regular Maintenance

```bash
# Update system weekly
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

# Update Docker containers
cd /docker/portainer
docker compose pull
docker compose up -d

# Clean up Docker
docker system prune -a --volumes

# Check security logs
sudo tail -50 /var/log/auth.log
sudo fail2ban-client status sshd

# Backup configuration
sudo tar -czf /backups/midway-config-$(date +%Y%m%d).tar.gz /docker /etc/ssh /etc/netplan
```

### Log Review

```bash
# SSH authentication logs
sudo grep "Accepted\|Failed" /var/log/auth.log | tail -50

# Fail2Ban activity
sudo tail -50 /var/log/fail2ban.log

# UFW firewall logs
sudo tail -50 /var/log/ufw.log

# Docker logs
docker logs portainer --tail 100
```

## Backup & Recovery

### Configuration Backup

```bash
# Create backup script
nano ~/backup-midway.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Docker configurations
tar -czf $BACKUP_DIR/docker-$DATE.tar.gz /docker

# Backup SSH configuration
tar -czf $BACKUP_DIR/ssh-$DATE.tar.gz /etc/ssh

# Backup network configuration
tar -czf $BACKUP_DIR/network-$DATE.tar.gz /etc/netplan

# Backup firewall rules
ufw status verbose > $BACKUP_DIR/ufw-rules-$DATE.txt

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.txt" -mtime +30 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
chmod +x ~/backup-midway.sh

# Test backup
~/backup-midway.sh

# Add to crontab for weekly backups
crontab -e
# Add: 0 2 * * 0 /home/username/backup-midway.sh
```

## Troubleshooting

**Cannot SSH to Midway Station?**

- Verify VM is running in Proxmox
- Check network connectivity: `ping 192.168.1.50`
- Verify UFW rules: `sudo ufw status`
- Check SSH service: `sudo systemctl status ssh`

**Cannot access other VMs through jump host?**

- Verify UFW on target VMs allows Midway Station IP
- Test direct connection from Midway Station to target
- Check SSH keys are properly installed
- Verify ProxyJump configuration in SSH config

**Portainer not accessible?**

- Check container is running: `docker ps | grep portainer`
- Verify UFW allows port 9443: `sudo ufw status`
- Check logs: `docker logs portainer`
- Try HTTP instead: `http://192.168.1.50:9000` (if configured)

**UFW blocking legitimate traffic?**

- Review UFW logs: `sudo grep UFW /var/log/syslog`
- Temporarily disable to test: `sudo ufw disable`
- Add missing rules for required services

## Security Checklist

- [ ] Static IP configured and tested
- [ ] Root login disabled
- [ ] UFW firewall enabled and configured
- [ ] SSH hardened (banner, no root, strong ciphers)
- [ ] Fail2Ban installed and active
- [ ] Docker installed and secured
- [ ] Portainer deployed and accessible
- [ ] SSH keys generated and installed
- [ ] Jump host configuration tested
- [ ] Access from local network verified
- [ ] Access from external network blocked
- [ ] Logs reviewed for suspicious activity
- [ ] Backup procedures established
- [ ] Documentation updated

## References

- [Ubuntu VM Template Guide](../ubuntu-vm-template-creation.md)
- [SSH Hardening Guide](../ssh-hardening-fail2ban.md)
- [Docker Installation Guide](../docker-engine-installation.md)
- [Portainer Setup Guide](../portainer-docker-management.md)
- [UFW Firewall Guide](https://help.ubuntu.com/community/UFW)

---

*Part of the SGC Home Network infrastructure project*
