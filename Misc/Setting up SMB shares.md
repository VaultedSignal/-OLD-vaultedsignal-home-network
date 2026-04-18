# VS Home Network - Samba (SMB) File Sharing Setup

Guide for installing and configuring Samba file sharing on Ubuntu/Debian for Windows network file access.

## Overview

Samba enables Linux servers to share files and folders with Windows, macOS, and other Linux systems using the SMB/CIFS protocol. This allows seamless network file sharing across different operating systems, making your Linux server accessible like a Windows network share.

## Why Use Samba?

- 🪟 **Windows Compatibility**: Native Windows file sharing protocol
- 🍎 **Cross-Platform**: Works with Windows, macOS, Linux
- 🌐 **Network Sharing**: Access files from any device on your network
- 📁 **Simple Access**: Mount as network drive in Windows/macOS
- 🔒 **Flexible Security**: Support for guest access or authentication
- ⚡ **Performance**: Fast network file transfers

## Use Cases

- Share media libraries (movies, TV shows, music) with Jellyfin/Plex
- Access VM storage from Windows workstation
- Network backup destination
- Shared documents and files across devices
- Central file server for home/office network

## Prerequisites

- linux based system
- Root or sudo access
- Directory to share already created
- Static IP address configured (recommended)
- Firewall access configured

## Installation

### Install Samba Server

```bash
# Update package lists
sudo apt update

# Install Samba
sudo apt install -y samba samba-common-bin

# Verify installation
smbd --version
```

**Expected output**:

```bash
Version 4.15.13-Ubuntu
```

### Verify Service is Running

```bash
# Check Samba service status
sudo systemctl status smbd

# Enable Samba to start on boot
sudo systemctl enable smbd

# Start Samba if not running
sudo systemctl start smbd
```

## Configuration

### Backup Original Configuration

Always backup before making changes:

```bash
# Backup original config
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

# View current config (optional)
sudo cat /etc/samba/smb.conf
```

### Edit Samba Configuration

```bash
# Edit main configuration file
sudo nano /etc/samba/smb.conf
```

### Global Settings

Add or modify these settings in the `[global]` section:

```conf
[global]
   workgroup = WORKGROUP
   server string = %h server (Samba, Ubuntu)
   
   # Networking
   interfaces = 192.168.1.0/24 lo
   bind interfaces only = yes
   
   # Security
   security = user
   map to guest = bad user
   guest account = nobody
   
   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   
   # Misc
   dns proxy = no
```

**Key settings explained**:

- **workgroup**: Windows workgroup name (default: WORKGROUP)
- **interfaces**: Limit to local network for security
- **map to guest = bad user**: Allow guest access for invalid usernames
- **guest account**: System user for guest connections

### Example Directories to share

Create the directories you want to share:

```bash
# Example: Create media share directories
sudo mkdir -p /shares/media
sudo mkdir -p /shares/backups
sudo mkdir -p /shares/documents

# Set permissions for guest access
sudo chmod 777 /shares/media
sudo chmod 777 /shares/backups
sudo chmod 777 /shares/documents

# Or set specific owner
sudo chown -R nobody:nogroup /shares/media
```

## Share Configuration Examples

### Example 1: Public Guest Share (Read/Write)

Add to `/etc/samba/smb.conf`:

```conf
[Media]
   comment = Media Files - Movies and TV Shows
   path = /drives/alfheim
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
```

### Example 2: Read-Only Guest Share

```conf
[Public]
   comment = Public Read-Only Files
   path = /shares/public
   browseable = yes
   read only = yes
   guest ok = yes
   force user = nobody
   force group = nogroup
```

### Example 3: Authenticated User Share

```conf
[Private]
   comment = Private User Files
   path = /shares/private
   browseable = yes
   read only = no
   guest ok = no
   valid users = admin, user1
   force user = admin
   create mask = 0660
   directory mask = 0770
```

### Example 4: Multiple Media Shares

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

[Anime]
   comment = Anime Library
   path = /drives/aincrad/anime-shows
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777

[Downloads]
   comment = Download Folder
   path = /drives/theseed/downloads
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
```

### Share Configuration Parameters Explained

| Parameter | Description | Common Values |
| ----------- | ------------- | --------------- |
| `comment` | Description shown in Windows | Any text |
| `path` | Local directory to share | `/path/to/folder` |
| `browseable` | Show in network browser | `yes` or `no` |
| `read only` | Prevent writing | `yes` (read-only) or `no` (read/write) |
| `guest ok` | Allow guest access | `yes` or `no` |
| `valid users` | Allowed usernames | `user1, user2` |
| `force user` | Override file owner | `nobody`, `admin` |
| `force group` | Override file group | `nogroup`, `users` |
| `create mask` | Permission for new files | `0777`, `0660` |
| `directory mask` | Permission for new folders | `0777`, `0770` |

### Permission Masks Reference

| Mask | Meaning | Use Case |
| ------ | --------- | ---------- |
| `0777` | Full access (rwx for all) | Public guest shares |
| `0775` | Owner/group full, others read | Semi-private shares |
| `0770` | Owner/group only | Private shares |
| `0660` | Owner/group read/write only | Secure file shares |
| `0644` | Owner write, all read | Read-mostly shares |

## User Authentication Setup

### Create Samba Users

For authenticated shares, create Samba users:

```bash
# Create system user (if doesn't exist)
sudo useradd -M -s /usr/sbin/nologin sambauser

# Set Samba password for user
sudo smbpasswd -a sambauser
# Enter password when prompted

# Enable the user
sudo smbpasswd -e sambauser

# List Samba users
sudo pdbedit -L -v
```

### Modify Share for Authentication

```conf
[Secure]
   comment = Authenticated Share
   path = /shares/secure
   browseable = yes
   read only = no
   guest ok = no
   valid users = sambauser admin
   force user = sambauser
   create mask = 0660
   directory mask = 0770
```

## Apply Configuration

### Test Configuration Syntax

```bash
# Test for syntax errors
sudo testparm

# Test and show full config
sudo testparm -s
```

**Fix any errors** before restarting the service.

### Restart Samba Service

```bash
# Restart Samba to apply changes
sudo systemctl restart smbd

# Verify service is running
sudo systemctl status smbd

# Check for errors in logs
sudo tail -f /var/log/samba/log.smbd
```

## Firewall Configuration

### Allow Samba Through UFW

```bash
# Allow Samba from local network
sudo ufw allow from 192.168.1.0/24 to any app Samba

# Or allow Samba from anywhere (less secure)
sudo ufw allow Samba

# Verify firewall rules
sudo ufw status verbose
```

### Manual Port Configuration

If UFW doesn't recognize Samba app:

```bash
# Samba uses these ports
sudo ufw allow from 192.168.1.0/24 to any port 139 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 137 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 138 proto udp
```

**Samba Ports**:

- **139/TCP**: NetBIOS Session Service
- **445/TCP**: Microsoft-DS (SMB over TCP)
- **137/UDP**: NetBIOS Name Service
- **138/UDP**: NetBIOS Datagram Service

## Accessing Shares

### From Windows

#### Method 1: File Explorer

1. Open **File Explorer**
2. In the address bar, type:

   ```txt
   \\192.168.0.1
   ```

   Or with share name:

   ```txt
   \\192.168.0.1\Media
   ```

3. Press **Enter**
4. Browse available shares

#### Method 2: Map Network Drive

1. Open **File Explorer**
2. Right-click **"This PC"** → **"Map network drive"**
3. **Drive letter**: Choose a letter (e.g., Z:)
4. **Folder**: `\\192.168.0.1\Media`
5. ☑ **Reconnect at sign-in**
6. Click **Finish**

#### Method 3: Run Command

1. Press **Win + R**
2. Type: `\\192.168.0.1`
3. Press **Enter**

### From macOS

#### Method 1: Finder

1. Open **Finder**
2. Press **Cmd + K** (or Go → Connect to Server)
3. Server Address:

   ```txt
   smb://192.168.0.1/Media
   ```

4. Click **Connect**
5. Select **Guest** or enter credentials

#### Method 2: Mount Command

```bash
# Create mount point
mkdir ~/shares/media

# Mount share
mount -t smbfs //guest@192.168.1.102/Media ~/shares/media
```

### From Linux

#### Method 1: File Manager

Most Linux file managers support SMB:

1. Open file manager (Nautilus, Dolphin, Thunar)
2. Go to **Network** or press **Ctrl + L**
3. Enter:

   ```txt
   smb://192.168.1.102/Media
   ```

4. Press **Enter**

#### Method 2: Command Line Mount

```bash
# Install cifs-utils
sudo apt install cifs-utils -y

# Create mount point
sudo mkdir -p /mnt/samba/media

# Mount as guest
sudo mount -t cifs //192.168.1.102/Media /mnt/samba/media -o guest,uid=1000,gid=1000

# Mount with credentials
sudo mount -t cifs //192.168.1.102/Media /mnt/samba/media -o username=sambauser,password=yourpassword,uid=1000,gid=1000
```

#### Method 3: Permanent Mount (fstab)

```bash
# Edit fstab
sudo nano /etc/fstab
```

Add line:

```conf
//192.168.1.102/Media /mnt/samba/media cifs guest,uid=1000,gid=1000,iocharset=utf8 0 0
```

Or with credentials:

```conf
//192.168.1.102/Media /mnt/samba/media cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,iocharset=utf8 0 0
```

Create credentials file:

```bash
sudo nano /root/.smbcredentials
```

Add:

```txt
username=sambauser
password=yourpassword
domain=WORKGROUP
```

Secure it:

```bash
sudo chmod 600 /root/.smbcredentials
```

Mount all:

```bash
sudo mount -a
```

## Management & Maintenance

### View Connected Users

```bash
# List active connections
sudo smbstatus

# Show connected users only
sudo smbstatus -b

# Show locked files
sudo smbstatus -L
```

### Manage Users

```bash
# List Samba users
sudo pdbedit -L

# Add user
sudo smbpasswd -a username

# Change user password
sudo smbpasswd username

# Delete user
sudo smbpasswd -x username

# Disable user
sudo smbpasswd -d username

# Enable user
sudo smbpasswd -e username
```

### Monitor Logs

```bash
# View Samba logs
sudo tail -f /var/log/samba/log.smbd

# View specific client logs
sudo tail -f /var/log/samba/log.192.168.1.100

# Check for errors
sudo grep -i error /var/log/samba/log.smbd
```

### Restart Services

```bash
# Restart Samba
sudo systemctl restart smbd

# Restart NetBIOS name service
sudo systemctl restart nmbd

# Restart both
sudo systemctl restart smbd nmbd
```

## Troubleshooting

**Cannot see server in Windows Network?**

- Ensure NetBIOS name service is running: `sudo systemctl start nmbd`
- Check Windows network discovery is enabled
- Try accessing directly by IP: `\\192.168.1.102`
- Verify firewall allows ports 137-138 UDP

**Access denied when connecting?**

- Check share permissions: `ls -la /path/to/share`
- Verify `guest ok = yes` for guest access
- For user authentication, check password: `sudo smbpasswd username`

**Cannot write to share?**

- Verify `read only = no` in share config
- Check directory permissions: `chmod 777 /path/to/share`
- Ensure `create mask = 0777` is set

**Slow performance?**

- Add to `[global]` section:

  ```conf
  socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
  min receivefile size = 16384
  use sendfile = true
  aio read size = 16384
  aio write size = 16384
  ```

**Configuration syntax errors?**

- Test config: `sudo testparm`
- Check for typos in parameter names
- Ensure proper indentation

**Service won't start?**

- Check logs: `sudo journalctl -xeu smbd`
- Verify config syntax: `sudo testparm`
- Check port conflicts: `sudo netstat -tulpn | grep -E '139|445'`

## Security Best Practices

1. **Restrict to local network**: Use `interfaces` and `bind interfaces only`
2. **Use authentication**: Avoid guest shares for sensitive data
3. **Limit permissions**: Use minimal required permissions (0770 instead of 0777)
4. **Firewall rules**: Only allow from trusted networks
5. **Regular updates**: Keep Samba updated for security patches
6. **Monitor access**: Review logs regularly
7. **Strong passwords**: Enforce strong Samba user passwords
8. **Disable unused protocols**: Set `min protocol = SMB2`

### Enhanced Security Configuration

```conf
[global]
   # Disable SMB1 (security risk)
   min protocol = SMB2
   
   # Encryption (SMB3 only)
   server smb encrypt = desired
   
   # Restrict to local network
   interfaces = 192.168.1.0/24 lo
   bind interfaces only = yes
   
   # Limit hosts
   hosts allow = 192.168.1.0/24 127.0.0.1
   hosts deny = 0.0.0.0/0
   
   # Disable unnecessary features
   disable netbios = yes
   smb ports = 445
```

## Performance Optimization

### For Large Files (Media)

```conf
[global]
   # Optimize for large file transfers
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
   use sendfile = yes
   min receivefile size = 16384
   aio read size = 16384
   aio write size = 16384
   
   # Disable unnecessary features
   strict locking = no
   
[Media]
   # Specific share optimizations
   strict allocate = yes
   allocation roundup size = 4096
```

## Complete Configuration Example

Here's a complete working configuration:

```conf
[global]
   workgroup = WORKGROUP
   server string = SGC File Server
   security = user
   map to guest = bad user
   guest account = nobody
   
   # Network
   interfaces = 192.168.0.0/24 lo
   bind interfaces only = yes
   
   # Security
   min protocol = SMB2
   hosts allow = 192.168.1.0/24 127.0.0.1
   
   # Performance
   socket options = TCP_NODELAY SO_RCVBUF=524288 SO_SNDBUF=524288
   use sendfile = yes
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 1000

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

[Downloads]
   comment = Downloads
   path = /drives/theseed/downloads
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
```

## References

- [Samba Official Documentation](https://www.samba.org/samba/docs/)
- [Ubuntu Samba Guide](https://ubuntu.com/server/docs/samba-file-server)
- [Samba Wiki](https://wiki.samba.org/)
- [SMB Protocol Documentation](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/f210069c-7086-4dc2-885e-861d837df688)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
