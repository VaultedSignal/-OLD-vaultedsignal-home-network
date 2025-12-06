# 🖥️ VM 101: Midway Station (Management & Jump Server)

**Author:** VaultedSignal
**Date:** 06-12-2025
**Purpose:** Primary entry point for the network, management server, and Docker host for lightweight services (Portainer).
**VM ID:** 101

---

## 🛠️ Proxmox VM Configuration

Specific hardware and boot settings for the Management Server.

| Section | Parameter | Value | Notes |
| :--- | :--- | :--- | :--- |
| **General** | VM ID | `101` | |
| | Name | `midway-station` | |
| **OS** | Image | Ubuntu Server | |
| | Type | Linux | |
| **System** | Machine | `q35` | |
| | BIOS | `SeaBIOS` | |
| | SCSI Controller | `VirtIO SCSI single` | |
| **Disk** | Size | `32 GB` | OS Drive |
| | Cache | `Write through` | |
| | Discard | **Checked** | Important for SSD health |
| **CPU** | Sockets/Cores | 1 Socket / 2 Cores | |
| | Type | `host` | |
| **Memory** | RAM | `4096 MB` | |
| **Network** | Bridge | Default | `vmbr0` (usually) |

### Options (Boot/Shutdown)

| Option | Value | Rationale |
| :--- | :--- | :--- |
| **Start at boot** | **Yes** | Essential for a management server. |
| **Startup Order** | `2` | Starts after DNS (Prometheus, Order 1) is up. |
| **Startup Delay** | `0` | No extra delay needed. |
| **Shutdown Timeout** | Default | Standard timeout. |

---

## 💾 Ubuntu Server Installation

1.  **Language:** English
2.  **Network:** Default (DHCP) - *Configure Static IP post-install.*
3.  **Storage:** Guided configuration (Default).
4.  **Profile:**
    * **Name:** [Your Full Name]
    * **Server Name:** `midway-station`
    * **Username:** `$username`
5.  **SSH/Apps:** Skip "Ubuntu Pro", leave SSH unchecked (configure manually later), leave apps unchecked.
6.  **Reboot:** Stop VM in Proxmox, remove ISO, start VM.

---

## ⚙️ Post-Installation Setup

### 1. Update and Clean
```bash
sudo apt update && sudo apt upgrade -y
sudo apt clean && sudo apt autoremove && sudo apt autoclean
```

### 2. User Security
Disable root login for security.
```bash
sudo passwd -l root
```

### 3. Create Directory Structure
```bash
sudo mkdir -p /docker/portainer
```

### 4. Network Configuration (Netplan)
Set a static IP to ensure the management server is always accessible at the same address.

1.  Check interface name:
    ```bash
    ip a
    ```
2.  Edit configuration:
    ```bash
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```
3.  Paste configuration (adjust indentation carefully):
    ```yaml
    network:
      version: 2
      ethernets:
        enp6s18:
          dhcp4: no
          addresses: [$midway-station-ip/24]
          routes:
            - to: default
              via: $modem-ip
          nameservers:
            addresses: [$prometheus-ip, 1.1.1.1]
    ```
4.  Apply changes:
    ```bash
    sudo netplan apply
    ```

---

## 🛡️ Security Hardening (Firewall & Fail2Ban)

### 1. UFW Firewall
Allow SSH only from the local LAN.

| Command | Description |
| :--- | :--- |
| \`sudo ufw allow from $lan-ip/24 to any port 22\` | Allow SSH from LAN only. |
| \`sudo ufw deny 22/tcp\` | Block external SSH. |
| \`sudo ufw enable\` | Enable firewall. |
| \`sudo ufw status verbose\` | Verify rules. |

### 2. Fail2Ban
Prevent brute-force attacks by ignoring the local network.

1.  Edit jail config:
    ```bash
    sudo nano /etc/fail2ban/jail.local
    ```
2.  Add whitelist:
    ```ini
    [DEFAULT]
    ignoreip = 127.0.0.1/8 $lan-ip/24
    ```
3.  Restart service:
    ```bash
    sudo systemctl restart fail2ban && sudo systemctl status fail2ban
    ```

---

## 🐳 Docker & Portainer Setup

### 1. Install Docker Engine
Follow the official documentation: [Docker Install Guide](https://docs.docker.com/engine/install/ubuntu/)

### 2. Install Portainer (Container Management)
Reference: [Portainer Install Guide](https://docs.portainer.io/start/install-ce/server/docker/linux)

**Quick Setup:**
1.  Navigate to the directory:
    ```bash
    cd /docker/portainer
    ```
2.  Create the Compose file:
    ```bash
    sudo nano portainer-compose.yaml
    ```
3.  *Paste the Portainer compose content here (usually defines the image `portainer/portainer-ce:latest`, ports `9443:9443`, and volumes).*
4.  Run the container:
    ```bash
    docker compose -f portainer-compose.yaml up -d
    ```
