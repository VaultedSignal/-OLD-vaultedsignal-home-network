# 🛡️ VM 999: Prometheus (Pi-hole DNS Server)

**Author:** VaultedSignal
**Date:** 17-12-2025
**Purpose:** Dedicated host for Pi-hole DNS and DHCP service.

---

## 🛠️ Hardware

RaspberryPI 4b

## 💾 Debian Server Installation & Initial Setup

https://www.youtube.com/watch?v=y45hsd2AOpw

### 1. Post-Install VM Maintenance

```bash
# Update and Clean
su -
sudo apt update && sudo apt upgrade -y
sudo apt clean && apt autoremove && apt autoclean
sudo reboot now
```

### 2. Create Directory Structure

```bash
mkdir -p /docker/composefiles
```

### 3. Network Configuration (Debian Interfaces)

https://www.abelectronics.co.uk/kb/article/31/set-a-static-ip-address-on-raspberry-pi-os-trixie

---

## 🔒 Security Hardening (Firewall & SSH)

### 1. UFW Firewall

Restrict SSH access to the trusted **Midway Station** jump host.

1. Install UFW:

    ```bash
    apt install ufw -y
    ```

2. Configure rules (Note: these commands require running as root or with `sudo`):

    | Command | Description |
    | :--- | :--- |
    | `ufw allow from $midway-station-ip to any port 22` | Allow SSH from Midway Station only. |
    | `ufw deny 22/tcp` | Block all other SSH connections. |
    | `ufw enable` | Activate the firewall. |
    | `ufw status verbose` | Check firewall status. |

### 2. OpenSSH User Restriction

Only allow connections from specific users on the specific jump host.

1. Edit the configuration:

    ```bash
    nano /etc/ssh/sshd_config
    ```

2. Add or modify the user restriction:

    ```ini
    # Allowed Users
    AllowUsers $username-current-machine@$midway-station-ip
    ```

3. Restart SSH service:

    ```bash
    systemctl restart ssh
    ```

### 3. Fail2Ban

Whitelist the Midway Station IP.

1. Edit jail config:

    ```bash
    nano /etc/fail2ban/jail.local
    ```

2. Add whitelist:

    ```ini
    [DEFAULT]
    ignoreip = 127.0.0.1/8 $midway-station-ip
    ```

3. Restart service:

    ```bash
    systemctl restart fail2ban && systemctl status fail2ban
    ```

---

## 🐳 Docker & Portainer Setup

### 1. Install Docker Engine

Reference: [Docker Install Guide](https://docs.docker.com/engine/install/ubuntu/) </br>
My own document:

Use debian one PI one doesnt work

## 🤖 Portainer Agent Installation & Portainer Setup

Reference: [Portainer Agent Install Guide](https://docs.portainer.io/admin/environments/add/docker/agent) </br>
My own document:
