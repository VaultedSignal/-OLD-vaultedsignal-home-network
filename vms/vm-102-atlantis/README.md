# VS Home Network - VM 102: Atlantis - NAS & File Server

Dedicated network-attached storage and file serving machine with RAID 5 array and large capacity drives.

## Overview

Atlantis serves as the central storage hub for the SGC Home Network, providing reliable file storage through a RAID 5 array and additional high-capacity storage. It hosts media libraries, backup storage, and serves files via Samba (SMB) to network clients.

## Purpose & Role

- 💾 **Network Storage**: Centralized file storage for all network devices
- 🎬 **Media Library**: Hosts movies, TV shows, and standard content
- 🔄 **RAID Protection**: RAID 5 array provides redundancy and performance
- 📁 **File Sharing**: SMB/Samba shares for Windows/macOS/Linux clients
- 🔒 **Data Integrity**: Graceful shutdown protection for RAID arrays
- 📊 **High Capacity**: 24TB+ total storage across multiple volumes

## Storage Architecture

### Alfheim - RAID 5 Array (3x 8TB)

- **Type**: RAID 5 (mdadm software RAID)
- **Capacity**: ~16TB usable (with one disk parity)
- **Drives**: 3x 8TB HDDs passed through from Proxmox
- **Content**: Standard media (movies, TV shows, etc)
- **Mount Point**: `/drives/alfheim`
- **Protection**: Single drive failure tolerance

### Aincrad - Single Drive (24TB)

- **Type**: Single large capacity drive
- **Capacity**: 24TB
- **Content**: Anime content
- **Mount Point**: `/drives/aincrad`
- **Protection**: None

## VM Specifications

### Hardware Configuration

| Component | Specification | Notes |
| ----------- | --------------- | ------- |
| **VM ID** | 102 | |
| **Hostname** | atlantis | |
| **vCPU** | 2 cores | 1 socket, host CPU type |
| **Memory** | 16 GB (16384 MB) | For disk caching and file serving |
| **Boot Disk** | 128 GB | OS and Docker volumes |
| **Storage Drives** | 4x passthrough | 3x 8TB RAID + 1x 24TB |
| **Network** | vmbr0 | Default bridge |
| **OS** | Ubuntu Server LTS | Latest stable release |

### Proxmox VM Settings

#### General

- **VM ID**: 102
- **Name**: atlantis
- **Resource Pool**: Storage (optional)

#### System

- **Machine Type**: q35
- **BIOS**: SeaBIOS
- **SCSI Controller**: VirtIO SCSI single
- **Qemu Agent**: Enabled

#### Disks

**Boot Disk (SCSI0)**:

- **Size**: 128 GB
- **Cache**: Write through
- **Discard**: ✓ Enabled
- **SSD Emulation**: ✓ Enabled (if on SSD)

**Passthrough Disks** (see Disk Passthrough section):

- **SCSI1**: 8TB HDD (RAID member 1)
- **SCSI2**: 8TB HDD (RAID member 2)
- **SCSI3**: 8TB HDD (RAID member 3)
- **SCSI4**: 24TB HDD (Single drive)

#### CPU

- **Sockets**: 1
- **Cores**: 2
- **Type**: host

#### Memory

- **Memory**: 16384 MB (16 GB)
- **Ballooning**: Enabled

#### Network

- **Bridge**: vmbr0
- **Model**: VirtIO (paravirtualized)

#### Options - Critical for NAS

- **Start at boot**: ✓ Yes
- **Start/Shutdown order**: 2
- **Startup delay**: **60 seconds** (CRITICAL - allows RAID to initialize)
- **Shutdown timeout**: **180 seconds** (allows clean RAID shutdown/sync)

**Startup Order Rationale**:

- **Order 1**: Prometheus (DNS) - Must be first
- **Order 2**: Atlantis (NAS) - Starts after DNS, with 60s delay for RAID
- **Order 3+**: Other VMs - Can access Atlantis storage after it's ready

**Why These Settings Matter**:

- **60s Startup Delay**: RAID arrays need time to detect drives, assemble, and sync before dependent VMs start
- **180s Shutdown Timeout**: Ensures RAID can flush write cache, sync metadata, and cleanly stop the array

## Installation

### Ubuntu Server Installation

Follow standard Ubuntu Server installation:

1. **Language Selection**: English
2. **Keyboard Layout**: English (US) or your preference
3. **Network Configuration**: Accept DHCP (configure static IP later)
4. **Proxy Configuration**: Leave blank
5. **Mirror Configuration**: Use default Ubuntu archive
6. **Storage Configuration**: Use entire disk, LVM setup
7. **Profile Setup**:
   - **Your name**: Your full name
   - **Server name**: `atlantis`
   - **Username**: Your admin username
   - **Password**: Strong password
8. **Ubuntu Pro**: Skip
9. **SSH Setup**: Leave unchecked (configure manually with hardening)
10. **Featured Server Snaps**: Leave all unchecked
11. **Installation Complete**: Reboot when prompted

**Post-Installation**:

- In Proxmox, stop the VM
- Remove the ISO from CD/DVD drive
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
    iotop \
    ncdu \
    smartmontools \
    mdadm \
    parted \
    tree \
    net-tools

# Clean up
sudo apt clean
sudo apt autoremove -y
sudo apt autoclean

# Reboot
sudo reboot
```

### Disable Root Login

```bash
# Check root status
sudo passwd -S root

# Lock root account
sudo passwd -l root

# Verify
sudo passwd -S root
```

### Create Directory Structure

```bash
# Create mount points for storage drives
sudo mkdir -p /drives/alfheim  # RAID 5 array
sudo mkdir -p /drives/aincrad  # 24TB drive

# Create Docker directories
sudo mkdir -p /docker/composefiles

# Create backup directory
sudo mkdir -p /backups

# Set ownership
sudo chown -R $USER:$USER /docker
```

## Configuration

### Configure Static IP with Netplan

For setting up network configuration see: [Network configuring](</docs/networking/Network configuring.md>)

## Security Hardening

For setting up security see: [SSH & Fail2Ban Configuration](</docs/networking/SSH & Fail2Ban Configuration>)

## Docker Installation

For setting up docker see: [SSH & Fail2Ban Configuration](</docker/networking/README.md)

## Portainer Agent Installation

For setting up Portainer Agent see: [Portainer agent Configuration](</docker/portainer-agent/README.md)

## Storage Configuration

### Identify Attached Disks

```bash
# List all block devices
lsblk

# View detailed disk information
sudo fdisk -l

# Check for existing RAID arrays
cat /proc/mdstat

# View disk IDs (for fstab)
sudo blkid
```

**Expected output**:

```txt
NAME   SIZE TYPE MOUNTPOINT
sda    128G disk           # OS drive
├─sda1   1M part
├─sda2   2G part /boot
└─sda3 126G part
  └─...       /
sdb     24T disk           # 24TB single drive (Aincrad)
└─sdb1  24T part
sdc      8T disk           # RAID member 1
sdd      8T disk           # RAID member 2
sde      8T disk           # RAID member 3
```

### RAID 5 Array Setup (Alfheim)

#### Install mdadm

```bash
# Install RAID management tools
sudo apt install mdadm -y
```

#### Assemble Existing RAID Array

If the RAID array was previously created on this host or another:

```bash
# Scan and assemble all arrays
sudo mdadm --assemble --scan

# Or manually assemble specific array
sudo mdadm --assemble /dev/md127 /dev/sdc /dev/sdd /dev/sde
```

#### Check RAID Status

```bash
# Detailed RAID information
sudo mdadm --detail /dev/md127

# Quick status check
cat /proc/mdstat

# Check for errors
sudo mdadm --detail /dev/md127 | grep -i state
```

**Expected output**:

```txt
/dev/md127:
           Version : 1.2
     Creation Time : [Date]
        Raid Level : raid5
        Array Size : 15628053504 (14.55 TiB)
     Used Dev Size : 7814026752 (7.28 TiB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : [Recent Date]
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0
```

#### Create Filesystem (If New Array)

Only if creating a new RAID array:

```bash
# Format as ext4
sudo mkfs.ext4 /dev/md127

# Add filesystem label
sudo e2label /dev/md127 alfheim
```

#### Mount RAID Array

```bash
# Create mount point
sudo mkdir -p /drives/alfheim

# Mount the array
sudo mount /dev/md127 /drives/alfheim

# Verify mount
df -h | grep alfheim
```

### Single 24TB Drive Setup (Aincrad)

#### Partition (If New Drive)

Only if the drive is brand new:

```bash
# Create partition
sudo parted /dev/sdb
(parted) mklabel gpt
(parted) mkpart primary ext4 0% 100%
(parted) quit

# Format partition
sudo mkfs.ext4 /dev/sdb1

# Add label
sudo e2label /dev/sdb1 aincrad
```

#### Mount Single Drive

```bash
# Create mount point
sudo mkdir -p /drives/aincrad

# Mount the drive
sudo mount /dev/sdb1 /drives/aincrad

# Verify mount
df -h | grep aincrad
```

### Make Mounts Persistent (fstab)

**Critical**: Use UUIDs for stable mounting across reboots.

#### Get UUIDs

```bash
# Get UUID for RAID array
sudo blkid /dev/md127

# Get UUID for single drive
sudo blkid /dev/sdb1

# Or view all UUIDs
sudo blkid
```

**Example output**:

```txt
/dev/md127: UUID="53737aa6-c4c3-47c4-8a6b-4e046468a68f" TYPE="ext4"
/dev/sdb1: UUID="e18458e0-ef19-49cf-a9fa-5536340375ea" TYPE="ext4"
```

#### Edit fstab

```bash
# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup

# Edit fstab
sudo nano /etc/fstab
```

**Add these lines** (replace UUIDs with your actual values):

```fstab
# RAID 5 Array (Alfheim) - 3x 8TB drives
UUID=53737aa6-c4c3-47c4-8a6b-4e046468a68f /drives/alfheim ext4 defaults,nofail 0 2

# 24TB Single Drive (Aincrad)
UUID=e18458e0-ef19-49cf-a9fa-5536340375ea /drives/aincrad ext4 defaults,nofail 0 2
```

**Options explained**:

- `defaults`: Use default mount options
- `nofail`: Don't prevent boot if drive fails to mount
- `0`: Don't dump (backup) this filesystem
- `2`: Check filesystem after root (0=don't check, 1=root, 2=other)

#### Test fstab Configuration

```bash
# Unmount drives
sudo umount /drives/alfheim
sudo umount /drives/aincrad

# Test mounting from fstab
sudo mount -a

# Verify all mounts
df -h
ls /drives/alfheim
ls /drives/aincrad

# Reload systemd
sudo systemctl daemon-reload
```

### RAID Monitoring Setup

```bash
# Configure mdadm monitoring
sudo nano /etc/mdadm/mdadm.conf
```

Add:

```conf
# Send email alerts (configure mail first)
MAILADDR admin@example.com

# Monitor all arrays
DEVICE partitions
ARRAY /dev/md127 metadata=1.2 name=atlantis:127 UUID=53737aa6:c4c347c4:8a6b4e04:6468a68f
```

**Start monitoring**:

```bash
# Enable mdmonitor service
sudo systemctl enable mdmonitor
sudo systemctl start mdmonitor

# Check status
sudo systemctl status mdmonitor
```

## Samba (SMB) File Sharing

### Install Samba

For setting up Samba see: [Setting up SMB shares](</docs/networking/shares/Setting up SMB shares.md)

### Configure Samba Shares

```bash
# Backup original config
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# Edit configuration
sudo nano /etc/samba/smb.conf
```

**Add to [global] section**:

```conf
[global]
   workgroup = WORKGROUP
   server string = Atlantis NAS
   security = user
   map to guest = bad user
   guest account = nobody
   
   # Network restrictions
   interfaces = 192.168.1.0/24 lo
   bind interfaces only = yes
   
   # Performance tuning
   socket options = TCP_NODELAY SO_RCVBUF=524288 SO_SNDBUF=524288
   use sendfile = yes
   min receivefile size = 16384
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 1000
```

**Add shares for media libraries**:

```conf
[Movies]
   comment = Movie Library
   path = /drives/alfheim/movies
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777

[TV-Shows]
   comment = TV Show Library
   path = /drives/alfheim/tv-shows
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777

[Anime-Shows]
   comment = Anime TV Series
   path = /drives/aincrad/anime-shows
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777

[Anime-Movies]
   comment = Anime Films
   path = /drives/aincrad/anime-movies
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777

[Backups]
   comment = Network Backups
   path = /backups
   browseable = yes
   read only = no
   guest ok = no
   valid users = admin
   force user = admin
   create mask = 0660
   directory mask = 0770
```

### Set Proper Permissions

```bash
# Set permissions for media directories
sudo chmod -R 777 /drives/alfheim/movies
sudo chmod -R 777 /drives/alfheim/tv-shows
sudo chmod -R 777 /drives/aincrad/anime-shows
sudo chmod -R 777 /drives/aincrad/anime-movies

# Set ownership
sudo chown -R nobody:nogroup /drives/alfheim/movies
sudo chown -R nobody:nogroup /drives/alfheim/tv-shows
sudo chown -R nobody:nogroup /drives/aincrad/anime-shows
sudo chown -R nobody:nogroup /drives/aincrad/anime-movies
```

### Test and Restart Samba

```bash
# Test configuration for errors
sudo testparm

# Restart Samba services
sudo systemctl restart smbd
sudo systemctl restart nmbd

# Verify services are running
sudo systemctl status smbd
sudo systemctl status nmbd
```

## Monitoring & Maintenance

### RAID Monitoring

```bash
# Check RAID status
cat /proc/mdstat
sudo mdadm --detail /dev/md127

# Monitor in real-time
watch -n 5 cat /proc/mdstat

# Check for errors
sudo mdadm --detail /dev/md127 | grep -i "state\|failed"

# View RAID event log
sudo cat /var/log/syslog | grep mdadm
```

### Disk Health Monitoring

```bash
# Install smartmontools (if not already)
sudo apt install smartmontools -y

# Check SMART status for all RAID drives
sudo smartctl -a /dev/sdc
sudo smartctl -a /dev/sdd
sudo smartctl -a /dev/sde

# Check single drive
sudo smartctl -a /dev/sdb

# Run SMART test
sudo smartctl -t short /dev/sdc
sudo smartctl -t long /dev/sdc
```

### Storage Usage

```bash
# Check disk usage
df -h

# Detailed per-directory usage
sudo du -sh /drives/*

# Find large files
sudo find /drives -type f -size +10G -exec ls -lh {} \;

# Check inode usage
df -i
```

### Samba Connection Monitoring

```bash
# View active connections
sudo smbstatus

# View connected users
sudo smbstatus -b

# View locked files
sudo smbstatus -L

# Monitor Samba logs
sudo tail -f /var/log/samba/log.smbd
```

### System Performance

```bash
# Monitor I/O performance
sudo iotop

# Check disk I/O stats
iostat -x 5

# Monitor network throughput
iftop

# Overall system resources
htop
```

## Troubleshooting

### RAID Issues

**RAID array not assembling on boot?**

```bash
# Check mdadm.conf
sudo cat /etc/mdadm/mdadm.conf

# Manually assemble
sudo mdadm --assemble --scan

# Update initramfs
sudo update-initramfs -u

# Rebuild RAID configuration
sudo mdadm --detail --scan | sudo tee /etc/mdadm/mdadm.conf
```

**RAID degraded (disk failure)?**

```bash
# Check status
cat /proc/mdstat
sudo mdadm --detail /dev/md127

# If disk failed, remove it
sudo mdadm /dev/md127 --fail /dev/sdc
sudo mdadm /dev/md127 --remove /dev/sdc

# Add replacement disk (after physically replacing)
sudo mdadm /dev/md127 --add /dev/sdf

# Monitor rebuild
watch cat /proc/mdstat
```

**RAID rebuild taking forever?**

```bash
# Check rebuild speed
cat /proc/sys/dev/raid/speed_limit_min
cat /proc/sys/dev/raid/speed_limit_max

# Increase rebuild speed (use with caution)
echo 50000 | sudo tee /proc/sys/dev/raid/speed_limit_min
echo 200000 | sudo tee /proc/sys/dev/raid/speed_limit_max
```

### Storage Issues

**Cannot mount drive?**

```bash
# Check filesystem
sudo fsck -f /dev/md127
sudo fsck -f /dev/sdb1

# Check for errors
sudo dmesg | grep -i error
sudo journalctl -xe | grep -i error
```

**Drive not showing up?**

```bash
# Rescan SCSI bus
echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan

# Check kernel messages
sudo dmesg | tail -50

# Verify in Proxmox
# Check VM Hardware tab for attached disks
```

### Samba Issues

**Cannot access shares from Windows?**

```bash
# Check Samba is running
sudo systemctl status smbd
sudo systemctl status nmbd

# Test configuration
sudo testparm

# Check firewall
sudo ufw status | grep -i samba

# Verify network
ping 192.168.1.102
```

**Slow file transfers?**

```bash
# Check network speed
iperf3 -s  # On Atlantis
iperf3 -c 192.168.1.102  # From client

# Monitor disk I/O
sudo iotop

# Check Samba performance tuning in smb.conf
# Ensure socket options are set correctly
```

**Permission denied errors?**

```bash
# Check share permissions
ls -la /drives/alfheim/movies

# Check Samba user permissions
sudo pdbedit -L

# Verify force user/group settings in smb.conf
sudo testparm -s | grep -i "force user\|force group"
```

### Performance Issues

**High I/O wait?**

```bash
# Check what's using I/O
sudo iotop -o

# Check for disk errors
sudo smartctl -a /dev/sdc | grep -i error

# Monitor RAID performance
iostat -x 5 /dev/md127
```

**Out of space?**

```bash
# Check disk usage
df -h

# Find large directories
sudo du -sh /drives/*/* | sort -rh | head -20

# Find old large files
sudo find /drives -type f -size +5G -mtime +365
```

## Best Practices

1. **Monitor RAID health daily**: Check `cat /proc/mdstat` regularly
2. **Run SMART tests monthly**: Schedule long SMART tests for all drives
3. **Keep backups**: RAID is not a backup - maintain separate backups
4. **Graceful shutdowns**: Always use proper shutdown, never force power off
5. **Document changes**: Keep notes on configuration changes
6. **Test recovery**: Periodically test restoring from backups
7. **Update regularly**: Keep system and packages updated
8. **Monitor logs**: Review system and RAID logs for warnings
9. **Plan for growth**: Monitor storage usage trends
10. **Have spare drives**: Keep compatible spare drives for quick replacement

## Security Checklist

- [ ] Static IP configured
- [ ] Root login disabled
- [ ] UFW firewall enabled
- [ ] SSH restricted to jump host
- [ ] Fail2Ban configured
- [ ] Samba restricted to local network
- [ ] RAID monitoring enabled
- [ ] SMART monitoring configured
- [ ] Backup procedures established
- [ ] Documentation updated
- [ ] Tested from jump host
- [ ] Tested Samba access from clients
- [ ] Verified RAID assembles on boot

## References

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [mdadm Documentation](https://raid.wiki.kernel.org/index.php/RAID_setup)
- [Samba Documentation](https://www.samba.org/samba/docs/)
- [SMART Monitoring](https://www.smartmontools.org/)
- [Linux RAID Wiki](https://raid.wiki.kernel.org/)
- [Proxmox Disk Passthrough Guide](../proxmox-disk-passthrough.md)
- [Samba Setup Guide](../samba-smb-setup.md)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
