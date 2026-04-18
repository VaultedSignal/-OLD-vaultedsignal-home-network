# VS Home Network - VM 101: Midway Station - Management & Jump Server

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
| ----------- | --------------- |------- |
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

- **Order 1**: Midway Station (Jump server) - Starts after DNS is available
- **Order 2+**: Other VMs - Can access Midway Station for management

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

# Install useful utilities
sudo apt install -y \
    vim \
    htop \
    net-tools \
    curl \
    wget \
    git \

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

## Configuration

### Configure Static IP with Netplan

For setting up network configuration see: [Network configuring](</docs/networking/Network configuring.md>)

## Security Hardening

For setting up security see: [SSH & Fail2Ban Configuration](</docs/networking/SSH & Fail2Ban Configuration>)

## Docker Installation

For setting up docker see: [SSH & Fail2Ban Configuration](</docker/networking/README.md)

## Portainer Installation

For setting up Portainer see: [Portainer Configuration](</docker/portainer/README.md)

## Services & Access

### Accessible Services

| Service | Port | Protocol | Purpose | Access |
|---------|------|----------|---------|--------|
| SSH | 22 | TCP | Remote shell access | Local network only |
| Portainer | 9443 | TCP | Docker management | Local network only |

### Service URLs

- **Portainer**: `https://192.168.1.201:9443`
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

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
