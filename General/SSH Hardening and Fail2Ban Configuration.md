# 🔐 SSH Hardening and Fail2Ban Configuration

**Author:** [Your Name]
**Date:** [Date of last revision]
**Purpose:** Comprehensive guide for installing OpenSSH, configuring key-based authentication, securing the service (banners, no root login), and preventing brute-force attacks with Fail2Ban.
**Scope:** Works for Ubuntu Server and Proxmox (Debian).

---

## 🛠️ Part 1: SSH Server Installation and Basic Setup

### 1. Install and Enable OpenSSH
Update repositories and install the server package.

\`\`\`bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable --now ssh # Starts SSH and enables it at boot
sudo systemctl status ssh       # Verify status
\`\`\`

### 2. Configure SSH Warning Banner
Create a banner to display legal warnings to anyone attempting to connect.

1.  Create the banner file:
    \`\`\`bash
    sudo nano /etc/ssh/ssh_banner
    \`\`\`
2.  Paste the following content:
    \`\`\`text
    ****************************************************************
    * WARNING: Authorized users only. All activity is logged.      *
    ****************************************************************
    \`\`\`
3.  Save and exit.

### 3. Modify `sshd_config` Basics
Edit the main configuration file to apply basic security and the banner.

\`\`\`bash
sudo nano /etc/ssh/sshd_config
\`\`\`

| Setting | Action | Description |
| :--- | :--- | :--- |
| `PermitRootLogin` | Uncomment & set to `prohibit-password` | Prevents root from logging in via password (keys only if allowed). |
| `PrintLastLog` | Uncomment & set to `yes` | Shows the last login timestamp when you connect. |
| `Banner` | Uncomment & set to `/etc/ssh/ssh_banner` | Displays the warning file created above. |

4.  Restart SSH to apply changes:
    \`\`\`bash
    sudo systemctl restart ssh
    \`\`\`

---

## 🔑 Part 2: SSH Key Authentication (Client Side)

Setup keys on your local machine (Windows or Linux) to connect without passwords.

### 1. Generate SSH Keys

**Option A: Windows (PowerShell)**
\`\`\`powershell
# Create directory structure
New-Item -ItemType Directory -Force -Path "C:\Users\$env:USERNAME\.ssh\$hostname_target"

# Generate Key (Ed25519 is recommended over RSA)
ssh-keygen -t ed25519 -C "$hostname-target" -f "C:\Users\$env:USERNAME\.ssh\$hostname_target\$hostname_target"
\`\`\`

**Option B: Linux**
\`\`\`bash
mkdir -p "$HOME/.ssh/$hostname_target"
ssh-keygen -t ed25519 -C "$hostname_target" -f "$HOME/.ssh/$hostname_target/$hostname_target"
\`\`\`

### 2. Configure SSH Shortcut (config file)
This allows you to type `ssh target-name` instead of the full user/IP command.

**Windows:** `C:\Users\$username\.ssh\config`
**Linux:** `~/.ssh/config`

Add the following block for each server:

\`\`\`ssh-config
Host $target-hostname
    HostName XXX.XXX.XXX.XXX
    User $username-target-machine
    # Path to your private key file
    IdentityFile ~/.ssh/$target-hostname/$target-hostname 
    # Note: On Windows use path: C:\Users\YourUser\.ssh\...\keyfile
\`\`\`

---

## 🔒 Part 3: SSH Key Authentication (Server Side)

Configure the target server to accept the keys and disable passwords.

### 1. Install Public Key
Copy the content of your **public key** (ending in `.pub`) from your client machine.

1.  On the server, open the authorized keys file:
    \`\`\`bash
    mkdir -p ~/.ssh
    nano ~/.ssh/authorized_keys
    \`\`\`
2.  Paste the public key (one key per line).
3.  **Important:** Set correct permissions (SSH is strict about this):
    \`\`\`bash
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    \`\`\`

### 2. Enforce Key-Only Authentication
Once you have verified your key works, disable password logins for security.

\`\`\`bash
sudo nano /etc/ssh/sshd_config
\`\`\`

| Setting | Action | Description |
| :--- | :--- | :--- |
| `PubkeyAuthentication` | Uncomment & set to `yes` | Enables the use of SSH keys. |
| `AuthorizedKeysFile` | Uncomment | Ensures it points to `.ssh/authorized_keys`. |
| `PasswordAuthentication` | Uncomment & set to `no` | **Disables** password logins (Security Risk if keys aren't working). |
| `KbdInteractiveAuthentication` | Uncomment & set to `no` | Disables keyboard interactive prompts. |

3.  Restart SSH:
    \`\`\`bash
    sudo systemctl restart ssh
    \`\`\`

---

## 🛡️ Part 4: Fail2Ban Configuration

Install Fail2Ban to ban IPs that show malicious behavior (brute force attempts).

### 1. Install and Enable
\`\`\`bash
sudo apt install fail2ban -y
sudo systemctl enable --now fail2ban
\`\`\`

### 2. Configure Jail (Local Config)
Never edit `.conf` files; always copy to `.local`.

\`\`\`bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
\`\`\`

Add or modify the `[sshd]` section:

\`\`\`ini
[sshd]
enabled = true
port    = ssh
filter  = sshd
# CRITICAL: This must point to where SSH actually writes logs
logpath = /var/log/auth.log 
backend = %(sshd_backend)s
maxretry = 3       # Ban after 3 failures
bantime = 1h       # Ban for 1 hour
findtime = 10m     # Count failures within a 10 minute window
\`\`\`

### 3. Restart and Verify
\`\`\`bash
sudo systemctl restart fail2ban
sudo systemctl status fail2ban
\`\`\`

**Useful Commands:**
* Check banned IPs: `sudo fail2ban-client status sshd`
* Unban an IP: `sudo fail2ban-client set sshd unbanip XXX.XXX.XXX.XXX`
