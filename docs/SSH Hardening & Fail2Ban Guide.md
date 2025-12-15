# SSH Hardening & Fail2Ban Configuration

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
*  WARNING: Authorized users only. All activity is logged.    *
*                                                              *
*  Unauthorized access is strictly prohibited and will be     *
*  prosecuted to the fullest extent of the law.               *
*                                                              *
****************************************************************
```

Save and exit (Ctrl+X, Y, Enter).

### Basic SSH Configuration

Edit the SSH daemon configuration:

```bash
sudo nano /etc/ssh/sshd_config
```

**Initial hardening settings**:

| Setting | Value | Purpose |
|---------|-------|---------|
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
notepad C:\Users\$env:USERNAME\.ssh\config  # Windows
```

Add connection shortcut:

```ssh-config
Host target-hostname
    HostName 192.168.1.100
    User your-username
    Port 22
    IdentityFile ~/.ssh/target-hostname/target-hostname
    # Windows: IdentityFile C:\Users\YourUser\.ssh\target-hostname\target-hostname
    
Host atlantis
    HostName 192.168.1.102
    User admin
    IdentityFile ~/.ssh/atlantis/atlantis
    
Host prometheus
    HostName 192.168.1.999
    User admin
    IdentityFile ~/.ssh/prometheus/prometheus
```

**Usage**: Now you can simply type `ssh atlantis` instead of `ssh admin@192.168.1.102`

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
|---------|-------|---------|
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
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 10.0.0.0/8
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

## References

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [Fail2Ban Official Wiki](https://github.com/fail2ban/fail2ban/wiki)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh-keys)
- [NIST SSH Guidelines](https://nvlpubs.nist.gov/nistpubs/ir/2015/NIST.IR.7966.pdf)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)

---

*Part of the SGC Home Network infrastructure project*
