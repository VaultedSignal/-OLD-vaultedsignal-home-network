# 🛡️ VM 999: Prometheus (Pi-hole DNS Server)

**Author:** VaultedSignal
**Date:** 07-12-2025
**Purpose:** Dedicated host for Pi-hole DNS and DHCP service. This VM must be the first to start.
**VM ID:** 999

---

## 🛠️ Proxmox VM Configuration

This VM must have the **highest startup priority** as it provides DNS for the entire network.

| Section | Parameter | Value | Notes |
| :--- | :--- | :--- | :--- |
| **General** | VM ID | `999` | |
| | Name | `prometheus` | |
| **OS** | Image | Debian | |
| | Type | Linux | |
| **System** | Machine | `q35` | |
| | SCSI Controller | `VirtIO SCSI single` | |
| **Disk** | Size | `32 GB` | OS Drive |
| | Cache | `Write through` | |
| | Discard | **Checked** | |
| **CPU** | Sockets/Cores | 1 Socket / 1 Core | |
| | Type | `host` | |
| **Memory** | RAM | `2048 MB` | |

### Options (Boot/Shutdown)

| Option | Value | Rationale |
| :--- | :--- | :--- |
| **Start at boot** | **Yes** | **CRITICAL:** Must start with the Proxmox host. |
| **Startup Order** | `1` | **CRITICAL:** Highest priority to ensure DNS is available. |
| **Startup Delay** | Default (`0`) | |
| **Shutdown Timeout** | Default (`0`) | |

---

## 💾 Debian Server Installation & Initial Setup

1. **Installation:** Use the Debian Server ISO with default settings.
2. **Disk:** All in one partition.
3. **SSH:** Enable SSH during installation.
4. **Reboot:** Stop VM in Proxmox, remove ISO, start VM.

### 0. Optimize GRUB Bootloader

Skip the boot menu countdown for faster startup.

1. Elevate to superuser:

    ```bash
    su -
    ```

2. Edit GRUB configuration:

    ```bash
    nano /etc/default/grub
    ```

3. Ensure the following entries are set:

    ```ini
    GRUB_DEFAULT=0
    GRUB_TIMEOUT=0
    GRUB_TIMEOUT_STYLE=hidden
    GRUB_DISTRIBUTOR=`( . /etc/os-release && echo ${NAME} )`
    GRUB_CMDLINE_LINUX_DEFAULT="quiet"
    GRUB_CMDLINE_LINUX=""
    ```

4. Update GRUB configuration:

    ```bash
    update-grub
    ```

### 1. Post-Install VM Maintenance

```bash
# Update and Clean
su -
apt update && apt upgrade -y
apt clean && apt autoremove && apt autoclean
reboot now
```

### 2. Create Directory Structure

```bash
# These directories are typically not needed for a standard Pi-hole install, 
# but are included for consistency.
mkdir -p /drives
mkdir -p /docker/composefiles
```

### 3. Network Configuration (Debian Interfaces)

Set a static IP using the traditional Debian configuration file (`/etc/network/interfaces`).

1. Elevate to superuser:

    ```bash
    su -
    ```

2. Edit network configuration file:

    ```bash
    nano /etc/network/interfaces
    ```

3. Change interfaces file (assuming interface name `ens18`):

    ```ini
    auto lo
    iface lo inet loopback

    auto ens18
    iface ens18 inet static
            address $prometheus-ip
            netmask 255.255.255.0
            gateway $modem-ip
            dns-nameservers 127.0.0.1 1.1.1.1
    ```

4. Modify the resolver file to prevent external services from overwriting Pi-hole's local DNS pointer:

    ```bash
    nano /etc/resolv.conf
    ```

    ```text
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    ```

5. Restart networking:

    ```bash
    systemctl restart networking
    ```

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

## 🤖 Portainer Agent Installation & Portainer Setup

Reference: [Portainer Agent Install Guide](https://docs.portainer.io/admin/environments/add/docker/agent) </br>
My own document:
