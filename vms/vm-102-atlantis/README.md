# 💾 VM 102: Atlantis (NAS & File Server)

**Author:** VaultedSignal
**Date:** 06-12-2025
**Purpose:** Dedicated NAS and file serving machine, hosting large storage volumes (RAID 5 and 24TB single drive).
**VM ID:** 102

---

## 🛠️ Proxmox VM Configuration

The **Startup Delay** and **Shutdown Timeout** are crucial here to protect the RAID array.

| Section | Parameter | Value | Notes |
| :--- | :--- | :--- | :--- |
| **General** | VM ID | `102` | |
| | Name | `atlantis` | |
| **OS** | Image | Ubuntu Server | |
| | Type | Linux | |
| **System** | Machine | `q35` | |
| | SCSI Controller | `VirtIO SCSI single` | |
| **Disk** | Size | `128 GB` | OS Drive |
| | Cache | `Write through` | |
| | Discard | **Checked** | |
| **CPU** | Sockets/Cores | 1 Socket / 2 Cores | |
| | Type | `host` | |
| **Memory** | RAM | `16384 MB` | |

### Options (Boot/Shutdown)

| Option | Value | Rationale |
| :--- | :--- | :--- |
| **Start at boot** | **Yes** | |
| **Startup Order** | `2` | Starts after DNS (Prometheus, Order 1). |
| **Startup Delay** | `60` | **CRITICAL:** Allows time for RAID hardware/software to spin up before the next VM starts. |
| **Shutdown Timeout** | `180` | Allows 3 minutes for graceful file system unmounting/RAID sync. |

---

## 💾 Ubuntu Server Installation & Initial Setup

1. **Installation:** Use the Ubuntu Server ISO with default settings (English, keyboard, mirror).
2. **Network:** Default (DHCP) - *Configure Static IP post-install.*
3. **Storage:** Guided configuration (Default).
4. **Profile:** Use `$username` and server name `atlantis`.
5. **Reboot:** Stop VM in Proxmox, remove ISO, start VM.

### 1. Post-Install VM Maintenance

```bash
# Update and Clean
sudo apt update && sudo apt upgrade -y
sudo apt clean && sudo apt autoremove && sudo apt autoclean
sudo reboot now

# Disable Root Local Login
sudo passwd -l root
```

### 2. Create Directory Structure

```bash
sudo mkdir -p /drives         # For all mounted physical drives
sudo mkdir -p /docker/composefiles # For Docker configs
```

### 3. Network Configuration (Netplan)

Set a static IP using Netplan.

1. Check interface name:

    ```bash
    ip a
    ```

2. Edit configuration:

    ```bash
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```

3. Paste configuration:

    ```yaml
    network:
      version: 2
      ethernets:
        enp6s18:
          dhcp4: no
          addresses: [$atlantis-ip/24]
          routes:
            - to: default
              via: $modem-ip
          nameservers:
            addresses: [$prometheus-ip, 1.1.1.1]
    ```

4. Apply changes:

    ```bash

    sudo netplan apply
    ```

---

## 🔒 Security Hardening (Firewall & SSH)

### 1. UFW Firewall

Restrict access to the trusted **Midway Station** jump host.

| Command | Description |
| :--- | :--- |
| `sudo ufw allow from $midway-station-ip to any port 22` | Allow SSH from Midway Station only. |
| `sudo ufw deny 22/tcp` | Block all other SSH connections. |
| `sudo ufw enable` | Activate the firewall. |
| `sudo ufw status verbose` | Check firewall status. |

### 2. OpenSSH User Restriction

Only allow connections from specific users on the specific jump host.

1. Edit the configuration:

    ```bash
    sudo nano /etc/ssh/sshd_config
    ```

2. Add or modify the user restriction:

    ```ini
    AllowUsers $username-current-machine@$midway-station-ip
    ```

3. Restart SSH service:

    ```bash
    sudo systemctl restart ssh
    ```

### 3. Fail2Ban

Whitelist the Midway Station IP.

1. Edit jail config:

    ```bash
    sudo nano /etc/fail2ban/jail.local
    ```

2. Add whitelist:

    ```ini
    [DEFAULT]
    ignoreip = 127.0.0.1/8 $midway-station-ip
    ```

3. Restart service:

    ```bash
    sudo systemctl restart fail2ban && sudo systemctl status fail2ban
    ```

---

## 🗄️ Storage: RAID and Single Drive Mounting

### 1. RAID 5 Volume (alfheim)

This procedure assumes the RAID array was previously created on the host and passed through as individual drives (`/dev/sdc`, `/dev/sdd`, `/dev/sde`).

1. Install the RAID management tool:

    ```bash
    sudo apt update
    sudo apt install mdadm -y
    ```

2. Assemble the RAID array:

    ```bash
    sudo mdadm --assemble --scan
    # If the scan fails, assemble manually (adjust /dev/md127 as needed):
    sudo mdadm --assemble /dev/md127 /dev/sdc /dev/sdd /dev/sde
    ```

3. Check status:

    ```bash
    sudo mdadm --detail /dev/md127
    cat /proc/mdstat
    ```

4. Create mount point and mount:

    ```bash
    sudo mkdir -p /drives/alfheim
    sudo mount /dev/md127 /drives/alfheim
    ```

### 2. Single 24TB Volume (aincrad)

1. Check disk ID (assuming the partition is `/dev/sdb1`):

    ```bash
    sudo blkid /dev/sdb1
    ```

2. Create mount point:

    ```bash
    sudo mkdir -p /drives/aincrad
    ```

### 3. Make Mounts Persistent (`/etc/fstab`)

**CRITICAL:** Use the **UUIDs** found from `sudo blkid` for stable mounting.

1. Edit `fstab`:

    ```bash
    sudo nano /etc/fstab
    ```

2. Add entries (replace UUIDs with your actual values):

    ```fstab
    # RAID 5 3x 8TB drives mounted in /drives/alfheim
    UUID=53737aa6-c4c3-47c4-8a6b-4e046468a68f /drives/alfheim ext4 defaults 0 0

    # 24TB drive mounted in /drives/aincrad
    UUID=e18458e0-ef19-49cf-a9fa-5536340375ea /drives/aincrad ext4 defaults 0 0
    ```

    ```bash
    sudo systemctl daemon-reload
    sudo mount -a
    ls /drives/*/ # Verify contents
    ```
