# VS Home Network - SSH & Fail2Ban Configuration

Comprehensive security guide for hardening SSH access and implementing automated intrusion prevention.

## Overview

This guide covers securing SSH access to your servers through key-based authentication, security hardening, and automated brute-force protection using Fail2Ban. These configurations apply to Ubuntu Server, Debian, and Proxmox hosts.

## Why SSH Hardening Matters

- 🔒 **Password Attacks**: SSH is the #1 target for automated brute-force attacks
- 🎯 **Privilege Escalation**: Compromised root access leads to full system control
- 📊 **Attack Volume**: Exposed SSH servers receive thousands of login attempts daily
- 🛡️ **Defense Layers**: Multiple security measures provide defense in depth
- ⚡ **Zero Trust**: Assume all network connections are hostile

## Technology Stack

- **SSH Server**: OpenSSH
- **Authentication**: Ed25519 key pairs (recommended) or RSA
- **Intrusion Prevention**: Fail2Ban
- **Logging**: System auth logs
- **Supported OS**: Ubuntu, Debian, Proxmox VE

## Security Features Implemented

- ✅ Key-based authentication only (no passwords)
- ✅ Root login disabled or restricted
- ✅ Custom warning banner
- ✅ Automated brute-force protection
- ✅ Temporary IP banning for failed attempts
- ✅ Activity logging and monitoring
- ✅ Modern cryptographic standards

## Part 1: SSH Server Installation & Basic Hardening

### Install OpenSSH Server

```bash
# Update package index
sudo apt update

# Install OpenSSH server
sudo apt install openssh-server -y

# Enable and start SSH service
sudo systemctl enable --now ssh

# Verify service is running
sudo systemctl status ssh
```

### Create SSH Warning Banner

Display a legal warning to anyone attempting to connect:

```bash
# Create banner file
sudo nano /etc/ssh/ssh_banner
```

Add the following content:

```text
****************************************************************
*                                                              *
*  WARNING: Authorized users only. All activity is logged.     *
*                                                              *
*  Unauthorized access is strictly prohibited and will be      *
*  prosecuted to the fullest extent of the law.                *
*                                                              *
****************************************************************
```

Save and exit

### Basic SSH Configuration

Edit the SSH daemon configuration:

```bash
sudo nano /etc/ssh/sshd_config
```

**Initial hardening settings**:

| Setting | Value | Purpose |
| --------- | ------- | --------- |
| `PermitRootLogin` | `prohibit-password` | Prevents root password login (keys only) |
| `PrintLastLog` | `yes` | Shows last login time on connection |
| `Banner` | `/etc/ssh/ssh_banner` | Displays warning banner |
| `MaxAuthTries` | `3` | Limits authentication attempts per connection |
| `ClientAliveInterval` | `300` | Checks if client is alive every 5 minutes |
| `ClientAliveCountMax` | `2` | Disconnects after 2 failed checks |

**Apply changes**:

```bash
# Test configuration for syntax errors
sudo sshd -t

# Restart SSH service
sudo systemctl restart ssh
```

**Important**: Keep your current SSH session open and test new connections in a separate terminal to ensure you don't lock yourself out.

## Part 2: SSH Key Authentication (Client Side)

Generate and configure SSH keys on your local machine for passwordless authentication.

### Generate SSH Key Pair

#### On Windows (PowerShell)

```powershell
# Create directory for this host's keys
New-Item -ItemType Directory -Force -Path "C:\Users\$env:USERNAME\.ssh\hostname-target"

# Generate Ed25519 key pair (recommended)
ssh-keygen -t ed25519 -C "hostname-target" -f "C:\Users\$env:USERNAME\.ssh\hostname-target\hostname-target"

# Or generate RSA key pair (if Ed25519 not supported)
ssh-keygen -t rsa -b 4096 -C "hostname-target" -f "C:\Users\$env:USERNAME\.ssh\hostname-target\hostname-target"
```

#### On Linux/macOS

```bash
# Create directory for this host's keys
mkdir -p ~/.ssh/hostname-target

# Generate Ed25519 key pair (recommended)
ssh-keygen -t ed25519 -C "hostname-target" -f ~/.ssh/hostname-target/hostname-target

# Or generate RSA key pair (if Ed25519 not supported)
ssh-keygen -t rsa -b 4096 -C "hostname-target" -f ~/.ssh/hostname-target/hostname-target
```

**When prompted**:

- Enter a strong passphrase (recommended for additional security)
- Or press Enter for no passphrase (less secure but more convenient)

**Output files**:

- `hostname-target` - Private key (keep secret, never share)
- `hostname-target.pub` - Public key (safe to share, install on servers)

### Configure SSH Client Config

Create a config file to simplify SSH connections:

**Windows**: `C:\Users\YourUsername\.ssh\config`
**Linux/macOS**: `~/.ssh/config`

```bash
# Create or edit config file
nano ~/.ssh/config  # Linux/macOS
notepad++ C:\Users\$env:USERNAME\.ssh\config  # Windows
```

example connection shortcut:

```txt
Host target-hostname
    HostName 192.168.1.100
    User your-username
    Port 22
    IdentityFile ~/.ssh/target-hostname/target-hostname
    # Windows: IdentityFile C:\Users\YourUser\.ssh\target-hostname\target-hostname 
```

**Usage**: Now you can simply type `ssh hostname` instead of `ssh admin@192.168.0.0`

### Set Proper Permissions (Linux/macOS)

```bash
# SSH config and directory
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/*/private-key-file
chmod 644 ~/.ssh/*/public-key-file.pub
```

## Part 3: SSH Key Authentication (Server Side)

Configure the server to accept your SSH keys and disable password authentication.

### Install Public Key on Server

#### Method 1: Using ssh-copy-id (Recommended)

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/hostname-target/hostname-target.pub username@server-ip

# Test connection
ssh username@server-ip
```

#### Method 2: Manual Installation

```bash
# On the server, create SSH directory if needed
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Edit authorized keys file
nano ~/.ssh/authorized_keys
```

Paste the content of your **public key** file (`hostname-target.pub`) into this file (one key per line).

**Set proper permissions**:

```bash
chmod 600 ~/.ssh/authorized_keys
chown $USER:$USER ~/.ssh/authorized_keys
```

### Test Key Authentication

Before disabling password authentication, verify your key works:

```bash
# Try connecting with your key
ssh -i ~/.ssh/hostname-target/hostname-target username@server-ip

# Or if you configured ~/.ssh/config
ssh hostname-target
```

**If successful**, you should connect without being prompted for a password (only key passphrase if you set one).

### Disable Password Authentication

**Critical**: Only do this after confirming key-based authentication works!

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config
```

**Security settings**:

| Setting | Value | Purpose |
| --------- | ------- | --------- |
| `PubkeyAuthentication` | `yes` | Enable SSH key authentication |
| `AuthorizedKeysFile` | `.ssh/authorized_keys` | Location of authorized keys |
| `PasswordAuthentication` | `no` | **Disable password login** |
| `PermitEmptyPasswords` | `no` | Never allow empty passwords |
| `ChallengeResponseAuthentication` | `no` | Disable keyboard-interactive auth |
| `KbdInteractiveAuthentication` | `no` | Same as above (newer name) |
| `UsePAM` | `no` | Disable PAM for strict key-only auth |

**Apply changes**:

```bash
# Test configuration
sudo sshd -t

# Restart SSH (keep current session open!)
sudo systemctl restart ssh
```

### Advanced SSH Hardening (Optional)

Additional security measures:

```bash
sudo nano /etc/ssh/sshd_config
```

```ssh-config
# Disable root login completely
PermitRootLogin no

# Restrict to specific users (replace with your usernames)
AllowUsers your-username admin

# Or restrict by group
AllowGroups ssh-users

# Disable X11 forwarding
X11Forwarding no

# Disable TCP forwarding
AllowTcpForwarding no

# Disable agent forwarding
AllowAgentForwarding no

# Use strong ciphers only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Use strong MACs
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

# Use strong key exchange algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Change default port (security through obscurity - optional)
Port 2222  # Choose any port > 1024
```

## Part 4: Fail2Ban Intrusion Prevention

Install and configure Fail2Ban to automatically ban IPs attempting brute-force attacks.

### Install Fail2Ban

```bash
# Install Fail2Ban
sudo apt install fail2ban -y

# Enable and start service
sudo systemctl enable --now fail2ban

# Verify status
sudo systemctl status fail2ban
```

### Configure Fail2Ban

**Never edit** `.conf` files directly - always create `.local` overrides:

```bash
# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit local configuration
sudo nano /etc/fail2ban/jail.local
```

### Basic Configuration

Find and modify the `[DEFAULT]` section:

```ini
[DEFAULT]
# Ban duration (can use: m=minutes, h=hours, d=days)
bantime = 1h

# Time window to count failures
findtime = 10m

# Number of failures before ban
maxretry = 3

# Action to take (ban IP with iptables)
banaction = iptables-multiport

# Email notifications (optional)
destemail = admin@example.com
sendername = Fail2Ban
```

### SSH-Specific Configuration

Find or create the `[sshd]` section:

```ini
[sshd]
enabled = true
port = ssh
# If you changed SSH port, specify it here:
# port = 2222
filter = sshd
logpath = /var/log/auth.log
backend = systemd
maxretry = 3
bantime = 1h
findtime = 10m
```

**For Proxmox hosts**, also add:

```ini
[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 1h
```

### Aggressive SSH Protection (Optional)

For high-security environments:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 2          # Lower threshold
bantime = 24h         # Longer ban
findtime = 5m         # Shorter window
```

### Apply Configuration

```bash
# Restart Fail2Ban
sudo systemctl restart fail2ban

# Verify it's running
sudo systemctl status fail2ban

# Check enabled jails
sudo fail2ban-client status
```

## Managing Fail2Ban

### View Status and Banned IPs

```bash
# View all jails
sudo fail2ban-client status

# View specific jail status (SSH)
sudo fail2ban-client status sshd

# View banned IPs for SSH jail
sudo fail2ban-client get sshd banned
```

### Manual IP Management

```bash
# Ban an IP manually
sudo fail2ban-client set sshd banip 192.168.1.100

# Unban an IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Unban all IPs
sudo fail2ban-client unban --all
```

### View Fail2Ban Logs

```bash
# View recent Fail2Ban activity
sudo tail -f /var/log/fail2ban.log

# View recent authentication attempts
sudo tail -f /var/log/auth.log

# Search for specific IP
sudo grep "192.168.1.100" /var/log/fail2ban.log
```

### Whitelist Trusted IPs

Prevent specific IPs from ever being banned:

```bash
sudo nano /etc/fail2ban/jail.local
```

Add to `[DEFAULT]` section:

```ini
[DEFAULT]
# Whitelist your trusted IPs (space-separated)
ignoreip = 127.0.0.1/8 ::1 192.168.2.0/24 10.0.0.0/8
```

Restart Fail2Ban:

```bash
sudo systemctl restart fail2ban
```

## Monitoring & Verification

### Check SSH Service

```bash
# View SSH service status
sudo systemctl status ssh

# View active SSH connections
who

# View detailed connection info
ss -tnp | grep :22

# View SSH logs
sudo tail -50 /var/log/auth.log
```

### Monitor Failed Login Attempts

```bash
# View recent failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Count failed attempts by IP
sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn

# View successful logins
sudo grep "Accepted publickey" /var/log/auth.log | tail -20
```

### Test Your Security

From an external machine or different IP:

```bash
# Test SSH connection with wrong password (should fail)
ssh username@server-ip

# After 3 attempts, IP should be banned
# Check if you're banned
sudo fail2ban-client status sshd
```

## Troubleshooting

**Locked out of server?**

- If you have console access (Proxmox, physical access), you can still log in
- Edit `/etc/ssh/sshd_config` and temporarily re-enable `PasswordAuthentication yes`
- Or add your key properly and disable passwords again

**SSH key not working?**

- Check file permissions: `ls -la ~/.ssh/`
- Private key should be 600, public key 644, .ssh directory 700
- Verify key is in server's `~/.ssh/authorized_keys`
- Check SSH logs on server: `sudo tail /var/log/auth.log`

**Fail2Ban not banning?**

- Verify service is running: `sudo systemctl status fail2ban`
- Check log file path is correct: `logpath = /var/log/auth.log`
- Ensure SSH jail is enabled: `sudo fail2ban-client status`
- Review Fail2Ban logs: `sudo tail /var/log/fail2ban.log`

**Accidentally banned yourself?**

- Use console access or another IP to connect
- Unban your IP: `sudo fail2ban-client set sshd unbanip YOUR_IP`
- Add your IP to whitelist to prevent future bans

**SSH service won't start after config changes?**

- Test configuration: `sudo sshd -t`
- Review error messages
- Check for syntax errors in `/etc/ssh/sshd_config`
- Restore from backup if needed

## Best Practices

1. **Always test before locking down**: Keep an active SSH session open while testing
2. **Use key passphrases**: Adds extra security layer to your private keys
3. **Backup private keys**: Store securely in multiple locations
4. **Regular updates**: Keep OpenSSH and Fail2Ban updated
5. **Monitor logs**: Regularly review authentication attempts
6. **Change default port**: Consider moving SSH to non-standard port
7. **Use SSH certificates**: For large deployments, consider SSH certificate authority
8. **Implement 2FA**: Add two-factor authentication with tools like Google Authenticator
9. **Principle of least privilege**: Only grant SSH access to those who need it
10. **Document everything**: Keep track of which keys are deployed where

## Security Checklist

- [ ] OpenSSH server installed and running
- [ ] Warning banner configured
- [ ] SSH keys generated on client
- [ ] Public keys installed on server
- [ ] Key-based authentication tested and working
- [ ] Password authentication disabled
- [ ] Root login disabled or restricted
- [ ] Fail2Ban installed and configured
- [ ] SSH jail enabled and active
- [ ] Trusted IPs whitelisted
- [ ] Configuration backed up
- [ ] Monitoring and alerting configured
- [ ] Documentation updated with key locations

## Advanced Topics

### SSH Jump Hosts / Bastion Servers

```ssh-config
# Connect through jump host
Host internal-server
    HostName 10.0.0.100
    User admin
    ProxyJump bastion-server
    
Host bastion-server
    HostName public-ip-address
    User admin
    IdentityFile ~/.ssh/bastion/bastion
```

### SSH Agent Forwarding

```bash
# Start SSH agent
eval $(ssh-agent)

# Add your key
ssh-add ~/.ssh/hostname-target/hostname-target

# Connect with agent forwarding
ssh -A username@server
```

### Port Forwarding

```bash
# Local port forwarding (access remote service locally)
ssh -L 8080:localhost:80 username@server

# Remote port forwarding (expose local service remotely)
ssh -R 8080:localhost:80 username@server

# Dynamic SOCKS proxy
ssh -D 1080 username@server
```

## Part 5: UFW Firewall Configuration

Configure UFW (Uncomplicated Firewall) to restrict SSH access to trusted networks only.

### Install UFW

```bash
# Install UFW (usually pre-installed on Ubuntu)
sudo apt install ufw -y

# Verify installation
ufw version
```

### Configure Default Policies

Set secure default policies before enabling the firewall:

```bash
# Deny all incoming connections by default
sudo ufw default deny incoming

# Allow all outgoing connections
sudo ufw default allow outgoing

# Disable routed traffic (unless you need it)
sudo ufw default deny routed
```

### Allow SSH from Local Network

**Critical**: Configure SSH access BEFORE enabling the firewall to avoid locking yourself out.

```bash
# Allow SSH from Midway Station (jump host) only
sudo ufw allow from 192.168.2.201 to any port 22 proto tcp

or

# Allow SSH from local network only (replace with your subnet)
sudo ufw allow from 192.168.2.0/24 to any port 22 proto tcp

# Explicitly deny SSH from everywhere else (optional, already covered by default deny)
sudo ufw deny 22/tcp


```

### Allow Additional Services (As Needed)

Add rules for other services running on the server:

```bash
# HTTP/HTTPS (if running web server)
sudo ufw allow from 192.168.2.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 443 proto tcp

# Proxmox web interface (if Proxmox host)
sudo ufw allow from 192.168.2.0/24 to any port 8006 proto tcp

# Portainer (if running)
sudo ufw allow from 192.168.2.0/24 to any port 9443 proto tcp

# Samba/SMB file sharing (if configured)
sudo ufw allow from 192.168.2.0/24 to any app Samba
# Or manually:
# sudo ufw allow from 192.168.1.0/24 to any port 139 proto tcp
# sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp
# sudo ufw allow from 192.168.1.0/24 to any port 137 proto udp
# sudo ufw allow from 192.168.1.0/24 to any port 138 proto udp
```

### Enable UFW

After configuring all necessary rules:

```bash
# Enable the firewall
sudo ufw enable

# You'll see a warning about disrupting existing SSH connections
# Type 'y' to proceed (your current session will remain active)
```

### Verify Configuration

```bash
# Check firewall status and rules
sudo ufw status verbose

# View numbered rules (useful for deletion)
sudo ufw status numbered

# Check listening services
sudo ss -tulpn
```

**Expected output**:

```txt
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    192.168.1.0/24
22/tcp                     DENY IN     Anywhere
```

### Managing UFW Rules

#### Add Rules

```bash
# Allow specific IP
sudo ufw allow from 192.168.1.100

# Allow specific IP to specific port
sudo ufw allow from 192.168.1.100 to any port 22

# Allow port range
sudo ufw allow 6000:6010/tcp

# Allow by service name
sudo ufw allow ssh
```

#### Delete Rules

```bash
# View numbered rules
sudo ufw status numbered

# Delete by number
sudo ufw delete 3

# Delete by rule specification
sudo ufw delete allow from 192.168.1.0/24 to any port 80
```

#### Modify Rules

```bash
# To change a rule, delete the old one and add a new one
sudo ufw delete allow 22/tcp
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

### UFW Logging

```bash
# Enable logging
sudo ufw logging on

# Set log level (low, medium, high, full)
sudo ufw logging medium

# View UFW logs
sudo tail -f /var/log/ufw.log

# Search for blocked connections
sudo grep "UFW BLOCK" /var/log/ufw.log

# View recent denied connections
sudo journalctl -u ufw -n 50
```

### Advanced UFW Configuration

#### Rate Limiting

Protect against brute-force attacks with rate limiting:

```bash
# Limit SSH connections (max 6 connections per 30 seconds)
sudo ufw limit from 192.168.1.0/24 to any port 22 proto tcp

# This automatically blocks IPs that exceed the limit
```

**Note**: Rate limiting can work alongside Fail2Ban for additional protection.

#### Application Profiles

UFW includes predefined application profiles:

```bash
# List available application profiles
sudo ufw app list

# View profile details
sudo ufw app info 'OpenSSH'
sudo ufw app info 'Samba'

# Allow by application profile
sudo ufw allow 'OpenSSH'
sudo ufw allow 'Samba'
```

#### Custom Application Profiles

Create custom profiles for your services:

```bash
# Create profile file
sudo nano /etc/ufw/applications.d/custom
```

Add:

```ini
[Portainer]
title=Portainer Docker Management
description=Portainer web interface for Docker
ports=9443/tcp

[Jellyfin]
title=Jellyfin Media Server
description=Jellyfin streaming server
ports=8096/tcp
```

Use the profile:

```bash
# Reload profiles
sudo ufw app update custom

# Allow the application
sudo ufw allow from 192.168.1.0/24 to any app Portainer
```

### UFW with IPv6

UFW supports IPv6 by default:

```bash
# Verify IPv6 is enabled
sudo nano /etc/default/ufw
```

Ensure:

```bash
IPV6=yes
```

Add IPv6 rules:

```bash
# Allow SSH from IPv6 local network
sudo ufw allow from fe80::/10 to any port 22 proto tcp

# Or disable IPv6 if not needed
sudo nano /etc/default/ufw
# Set: IPV6=no
sudo ufw reload
```

### Integration with Fail2Ban

UFW works seamlessly with Fail2Ban. Fail2Ban will add temporary ban rules to UFW/iptables:

```bash
# View all firewall rules including Fail2Ban
sudo iptables -L -n

# View Fail2Ban chains
sudo iptables -L f2b-sshd -n
```

### Disable/Reset UFW

If you need to disable or reset the firewall:

```bash
# Temporarily disable UFW
sudo ufw disable

# Re-enable UFW
sudo ufw enable

# Reset UFW to defaults (removes all rules)
sudo ufw reset
```

**Warning**: Resetting UFW removes all custom rules. You'll need to reconfigure everything.

### UFW Best Practices

1. **Configure before enabling**: Set up all necessary rules before enabling UFW
2. **Restrict by subnet**: Use network ranges (e.g., `192.168.1.0/24`) instead of allowing all
3. **Principle of least privilege**: Only open ports that are actively needed
4. **Document your rules**: Keep notes on why each port is open
5. **Regular audits**: Periodically review and remove unused rules
6. **Test thoroughly**: Verify services are accessible after enabling UFW
7. **Keep sessions open**: Maintain an active SSH session when making firewall changes
8. **Use rate limiting**: Combine with Fail2Ban for comprehensive protection
9. **Monitor logs**: Regularly review UFW logs for suspicious activity
10. **Backup rules**: Save your UFW configuration for disaster recovery

### Backup UFW Configuration

```bash
# Backup UFW rules
sudo cp -r /etc/ufw /root/ufw-backup-$(date +%Y%m%d)

# Or export rules to file
sudo ufw status numbered > ~/ufw-rules-$(date +%Y%m%d).txt

# View current rules
sudo cat /etc/ufw/user.rules
sudo cat /etc/ufw/user6.rules
```

### Restore UFW Configuration

```bash
# Disable UFW
sudo ufw disable

# Restore backup
sudo cp -r /root/ufw-backup-YYYYMMDD/* /etc/ufw/

# Re-enable UFW
sudo ufw enable
```

### Troubleshooting UFW

**Cannot access SSH after enabling UFW?**

- Access via console (Proxmox, physical access)
- Check if SSH rule exists: `sudo ufw status`
- Verify you're connecting from allowed subnet
- Temporarily disable: `sudo ufw disable`

**Service not accessible after adding rule?**

- Verify rule syntax: `sudo ufw status numbered`
- Check if service is actually running: `sudo systemctl status servicename`
- Ensure correct port number: `sudo ss -tulpn | grep port`
- Check application is listening on correct interface: `sudo netstat -tlnp`

**UFW blocking legitimate traffic?**

- Review logs: `sudo tail -f /var/log/ufw.log`
- Check for BLOCK entries matching your IP
- Add explicit allow rule for your IP/subnet
- Verify rule order (specific rules should come before general denies)

**UFW conflicts with Docker?**

- Docker manipulates iptables directly, bypassing UFW
- For Docker-specific firewall rules, see Docker documentation
- Consider using Docker's built-in firewall features

**Rules not applying?**

- Reload UFW: `sudo ufw reload`
- Check UFW is enabled: `sudo ufw status`
- Verify rule syntax: `sudo ufw --dry-run allow from 192.168.1.0/24`

### UFW Status Check

Regular status checks to ensure firewall is working correctly:

```bash
# Quick status check
sudo ufw status

# Detailed status with rule numbers
sudo ufw status numbered

# Verbose output with default policies
sudo ufw status verbose

# Check if UFW is active at boot
sudo systemctl is-enabled ufw

# View raw iptables rules
sudo iptables -L -v -n
sudo ip6tables -L -v -n
```

### Common UFW Rule Examples

```bash
# Allow SSH from specific IP only
sudo ufw allow from 192.168.1.50 to any port 22 proto tcp

# Allow multiple IPs
sudo ufw allow from 192.168.1.50 to any port 22
sudo ufw allow from 192.168.1.51 to any port 22

# Allow ping (ICMP)
sudo ufw allow proto icmp

# Allow all from trusted subnet
sudo ufw allow from 192.168.1.0/24

# Deny specific IP
sudo ufw deny from 203.0.113.100

# Allow outgoing on specific port
sudo ufw allow out 53/udp  # DNS

# Complex rule example
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp comment 'Allow local network to web service'
```

## References

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [Fail2Ban Official Wiki](https://github.com/fail2ban/fail2ban/wiki)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh-keys)
- [NIST SSH Guidelines](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [ufw Official documentation](https://help.ubuntu.com/community/UFW)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
