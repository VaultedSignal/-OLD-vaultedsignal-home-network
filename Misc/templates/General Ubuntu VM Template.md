# VS Home Network - General Ubuntu VM Template

Standardized process for creating secure, production-ready Ubuntu Server virtual machines on Proxmox.

## Overview

This guide provides a repeatable process for deploying hardened Ubuntu Server VMs on Proxmox VE. Following these steps ensures consistent configuration, proper security hardening, and integration with your network infrastructure including jump host access control.

## Why Use VM Templates?

- 🚀 **Rapid Deployment**: Spin up new VMs in minutes
- 🔒 **Consistent Security**: Every VM starts with the same hardening
- 📋 **Standardization**: Uniform configuration across infrastructure
- 🔄 **Repeatability**: Documented, tested deployment process
- 🛡️ **Defense in Depth**: Multiple security layers from the start

## Technology Stack

- **Hypervisor**: Proxmox VE
- **Operating System**: Ubuntu Server (Latest LTS recommended)
- **Network**: Netplan for static IP configuration
- **Security**: UFW, Fail2Ban, SSH hardening
- **Jump Host**: Midway Station for controlled access

## VM Creation Checklist

- [ ] VM created in Proxmox with proper settings
- [ ] Ubuntu Server installed
- [ ] Initial user created
- [ ] System updated
- [ ] Static IP configured
- [ ] Directory structure created
- [ ] Root login disabled
- [ ] UFW firewall configured
- [ ] SSH hardened with jump host restriction
- [ ] Fail2Ban configured
- [ ] Documentation updated
- [ ] Tested from jump host

## Part 1: Proxmox VM Creation

### VM Hardware Configuration

Create a new VM in Proxmox with these recommended settings:

#### General Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **VM ID** | Next available (e.g., 1-149 DHCP 150-199 for endpoints 200-250 for server 251-253 for networking) | Use sequential numbering |
| **Name** | Descriptive name |  |
| **Resource Pool** | (Optional) | Group related VMs |

#### OS Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **ISO Image** | Ubuntu Server (latest LTS) | Download from Ubuntu.com |
| **Guest OS Type** | Linux | |
| **Version** | 6.x - 2.6 Kernel | Default for Ubuntu |

#### System Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **Machine** | q35 | Modern, recommended |
| **BIOS** | SeaBIOS | Compatible with most systems |
| **SCSI Controller** | **VirtIO SCSI single** | Best performance and stability |
| **Qemu Agent** | Enabled | Recommended for better management |

#### Disks Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **Bus/Device** | SCSI 0 | Using VirtIO SCSI |
| **Storage** | local-lvm (or your storage) | |
| **Disk Size** | 32 GB minimum | 50-100 GB recommended |
| **Cache** | Write through | Balance of performance/safety |
| **Discard** | ✓ Enabled | Important for SSD TRIM support |
| **SSD Emulation** | ✓ If on SSD storage | Enables TRIM in guest |

#### CPU Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **Sockets** | 1 | Single socket recommended |
| **Cores** | 2-4 | Start with 2, increase as needed |
| **Type** | **host** | Uses host CPU features for best performance |

**Alternative CPU Types**:

- `x86-64-v2-AES` - Good compatibility and security
- `kvm64` - Maximum compatibility

#### Memory Tab

| Setting | Value | Notes |
|---------|-------|-------|
| **Memory (MiB)** | 4096 (4 GB) | Minimum for Ubuntu Server |
| **Ballooning** | Enabled | Allows dynamic memory adjustment |

**Recommended memory by use case**:

- Minimal server: 2048 MB (2 GB)
- Standard server: 4096 MB (4 GB)
- Docker host: 8192 MB (8 GB)
- Database server: 16384 MB (16 GB)

#### Network Tab

| Setting | Value | Notes |
| --------- | ------- | ------- |
| **Bridge** | vmbr0 | Default bridge |
| **Model** | VirtIO (paravirtualized) | Best performance |
| **Firewall** | Optional | Can use Proxmox firewall |

### VM Options Configuration

After creating the VM, configure additional options:

**Navigate to**: VM > Options

| Option | Setting | Purpose |
| -------- | --------- | --------- |
| **Start at boot** | Yes (✓) | VM starts automatically with Proxmox |
| **Start/Shutdown order** | Assign order number | Control startup sequence |
| **Startup delay** | 0-30 seconds | Wait time before starting (if dependencies exist) |
| **Shutdown timeout** | 60 seconds | Grace period before force shutdown |

**Startup Order Guidelines**:

1. **Order 1**: DNS/DHCP servers (Prometheus/Pi-hole)
2. **Order 2**: Storage/NAS servers
3. **Order 3**: Infrastructure services (Portainer, reverse proxy)
4. **Order 4+**: Application servers

**Example configuration**:

```txt
Prometheus (DNS): order=1, delay=0
Atlantis (Media): order=2, delay=10
Orion (Downloads): order=3, delay=5
```

## Part 2: Ubuntu Server Installation

### Installation Process

1. **Start the VM** and access the console
2. **Select language**: English
3. **Select keyboard layout**: English (US) or your preference
4. **Installation type**: Ubuntu Server (not minimal)
5. **Network configuration**:
   - Accept DHCP for now (we'll configure static IP later)
   - Note the assigned IP address

6. **Proxy configuration**: Leave blank (unless you use a proxy)
7. **Mirror configuration**: Use default Ubuntu archive mirror
8. **Storage configuration**:
   - Select **"Use an entire disk"**
   - Choose **"Set up this disk as an LVM group"**
   - Review and confirm (will erase disk)

9. **Profile setup**:
   - **Your name**: Admin or your name
   - **Server name**: Hostname (e.g., `atlantis`, `orion`)
   - **Username**: Your admin username
   - **Password**: Strong password (min 12 characters)

10. **Ubuntu Pro**: Skip (not required for home use)
11. **SSH Setup**: ✓ **Install OpenSSH server**
12. **Featured Server Snaps**: Leave all unchecked
13. **Installation**: Wait for completion
14. **Reboot**: When prompted

### Post-Installation Cleanup

After reboot and first login:

```bash
# Remove CD/DVD drive in Proxmox
# Navigate to: VM > Hardware > CD/DVD Drive > Remove
```

Or via command line on Proxmox host:

```bash
qm set <VM_ID> --delete ide2
```

## Part 3: Initial Configuration

### Create Directory Structure

Establish standard directory layout:

```bash
# Create mount points for data drives
sudo mkdir -p /drives

# Create Docker directories
sudo mkdir -p /docker/composefiles

# Create backup directory
sudo mkdir -p /backups

# Set proper ownership

sudo chown -R $USER:$USER /docker
```

**Standard directory structure**:

```txt
/
├── drives/              # Mount point for additional disks
│   ├── storage1/
│   └── storage2/
├── docker/              # Docker-related files
│   ├── composefiles/   # Docker Compose files
│   ├── appname/        # Per-application data
│   └── volumes/        # Docker volumes
└── backups/            # Local backups
```

### Disable Root Login

Lock the root account to prevent direct login:

```bash
# Check current root status
sudo passwd -S root

# Lock root account (prevents password login)
sudo passwd -l root

# Verify root is locked (should show "root L")
sudo passwd -S root
```

**Note**: Root can still be accessed via `sudo su -` by authorized users.

### System Updates

Apply all available updates:

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Upgrade distribution (if needed)
sudo apt full-upgrade -y

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

# Reboot to apply kernel updates
sudo reboot
```

## Part 4: Network Configuration

### Configure Static IP with Netplan

Ubuntu Server uses Netplan for network configuration.

#### Identify Network Interface

```bash
# List network interfaces
ip addr show

# Or use shorter command
ip a
```

**Common interface names**:

- `ens18` - Common in Proxmox VMs
- `enp6s18` - PCIe-based naming
- `eth0` - Legacy naming

#### Edit Netplan Configuration

```bash
# Backup original configuration
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak

# Edit configuration
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Configuration template**:

```yaml
network:
  version: 2
  ethernets:
    ens18:  # Replace with your interface name
      dhcp4: no
      addresses: 
        - 192.168.1.102/24  # Static IP with subnet mask
      routes:
        - to: default
          via: 192.168.1.1  # Gateway (router) IP
      nameservers:
        addresses:
          - 192.168.1.999   # Primary DNS (Pi-hole/Prometheus)
          - 1.1.1.1         # Secondary DNS (Cloudflare)
          - 1.0.0.1         # Tertiary DNS (Cloudflare)
```

**Multiple DNS example**:

```yaml
      nameservers:
        addresses:
          - 192.168.1.999   # Pi-hole
          - 8.8.8.8         # Google DNS
          - 1.1.1.1         # Cloudflare DNS
        search:
          - local           # Local domain suffix
```

#### Apply Network Configuration

```bash
# Test configuration syntax
sudo netplan try

# If successful, press Enter to accept
# Configuration will auto-revert if you lose connection

# Apply permanently
sudo netplan apply

# Verify new configuration
ip addr show
ping -c 4 1.1.1.1
ping -c 4 google.com
```

#### Troubleshooting Network Issues

```bash
# Check netplan configuration syntax
sudo netplan --debug apply

# View current configuration
sudo netplan get

# Restart networking service
sudo systemctl restart systemd-networkd

# Check DNS resolution
resolvectl status

# Test specific DNS server
nslookup google.com 1.1.1.1
```

## Part 5: SSH & Security Hardening

[Installing and configuring SSH, Fail2Ban and UFW](</docs/security/SSH & Fail2Ban Configuration.md>)

## Part 6: Docker and Portainer Agent

### Docker Installation

For setting up docker see: [SSH & Fail2Ban Configuration](</docker/networking/README.md)

### Portainer Agent Installation

For setting up Portainer Agent see: [Portainer agent Configuration](</docker/portainer-agent/README.md)

## Part 7: Additional Security Measures

### Install and Configure Automatic Updates

```bash
# Install unattended-upgrades
sudo apt install unattended-upgrades -y

# Configure automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Edit configuration for more control (optional)
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

### Enable QEMU Guest Agent

Improves integration with Proxmox:

```bash
# Install QEMU guest agent
sudo apt install qemu-guest-agent -y

# Enable and start service
sudo systemctl enable --now qemu-guest-agent

# Verify status
sudo systemctl status qemu-guest-agent
```

In Proxmox, enable the agent:

```bash
# On Proxmox host
qm set <VM_ID> --agent 1
```

### Configure Timezone

```bash
# List available timezones
timedatectl list-timezones

# Set timezone
sudo timedatectl set-timezone Europe/Amsterdam

# Verify
timedatectl
```

### Set Hostname (if needed)

```bash
# Change hostname
sudo hostnamectl set-hostname new-hostname

# Edit hosts file
sudo nano /etc/hosts

# Update line:
127.0.1.1    new-hostname

# Verify
hostnamectl
```

## Verification & Testing

### System Verification

```bash
# Check system information
hostnamectl

# Check network configuration
ip addr show
ip route show

# Check DNS resolution
resolvectl status
nslookup google.com

# Check SSH configuration
sudo sshd -t

# Check firewall status
sudo ufw status verbose

# Check Fail2Ban
sudo fail2ban-client status
```

### Security Testing

```bash
# Test SSH from jump host (should work)
# From Midway Station:
ssh admin@target-vm-ip

# Test SSH from other IP (should fail)
# From different machine:
ssh admin@target-vm-ip
# Should be blocked by UFW

# Check authentication logs
sudo tail -f /var/log/auth.log

# Check UFW logs
sudo tail -f /var/log/ufw.log
```

### Performance Check

```bash
# View system resources
htop

# Check disk usage
df -h

# Check disk I/O
iostat -x 1

# Network throughput test
iperf3 -c <server-ip>  # Requires iperf3 on both ends
```

## Creating a VM Template (Optional)

Convert this VM into a reusable template:

```bash
# On Proxmox host
# First, clean up the VM
qm shutdown <VM_ID>

# Wait for shutdown, then convert to template
qm template <VM_ID>
```

**Before creating template**:

1. Remove machine-specific data:

   ```bash
   # Inside VM before shutdown
   sudo cloud-init clean
   sudo rm -f /etc/ssh/ssh_host_*
   sudo truncate -s 0 /etc/machine-id
   sudo rm /var/lib/dbus/machine-id
   sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
   ```

2. Clear logs and history:

   ```bash
   sudo apt clean
   history -c
   ```

**Clone from template**:

```bash
# On Proxmox host
qm clone <TEMPLATE_ID> <NEW_VM_ID> --name new-vm-name --full
```

## Troubleshooting

**Cannot SSH from jump host?**

- Verify UFW allows jump host IP: `sudo ufw status`
- Check SSH is running: `sudo systemctl status ssh`
- Verify AllowUsers setting: `sudo grep AllowUsers /etc/ssh/sshd_config`
- Check authentication logs: `sudo tail /var/log/auth.log`

**Network not working after static IP?**

- Verify netplan syntax: `sudo netplan try`
- Check interface name is correct: `ip a`
- Verify gateway is reachable: `ping 192.168.1.1`
- Check DNS resolution: `nslookup google.com`

**UFW blocking legitimate traffic?**

- Check UFW logs: `sudo tail /var/log/ufw.log`
- Temporarily disable for testing: `sudo ufw disable`
- Verify rules: `sudo ufw status numbered`

**QEMU agent not working?**

- Verify installed: `systemctl status qemu-guest-agent`
- Check Proxmox side: VM > Options > QEMU Guest Agent
- Restart VM after enabling agent option

## Best Practices

1. **Document everything**: Keep notes on IP addresses, credentials, configurations
2. **Test thoroughly**: Verify each step before proceeding
3. **Keep backups**: Snapshot before major changes
4. **Use templates**: Create templates for common configurations
5. **Regular updates**: Schedule weekly update checks
6. **Monitor logs**: Review authentication and firewall logs regularly
7. **Least privilege**: Only open necessary ports and access
8. **Strong passwords**: Use complex, unique passwords for each VM
9. **SSH keys**: Implement key-based authentication (see SSH Hardening guide)
10. **Jump host model**: Always access VMs through trusted jump host

## Next Steps

After VM creation and hardening:

1. **Install Docker** (if needed) - see Docker Installation guide
2. **Deploy applications** - Install your services
3. **Set up monitoring** - Implement logging and metrics
4. **Configure backups** - Establish backup procedures
5. **Document VM** - Note purpose, services, ports, access methods
6. **Add to inventory** - Update infrastructure documentation

## References

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Netplan Documentation](https://netplan.io/)
- [UFW Guide](https://help.ubuntu.com/community/UFW)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Linux Hardening Guide](https://github.com/imthenachoman/How-To-Secure-A-Linux-Server)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
