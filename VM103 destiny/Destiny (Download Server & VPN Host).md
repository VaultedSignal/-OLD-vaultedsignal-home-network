# 📥 VM 103: Destiny (Download Server & VPN Host)

**Author:** VaultedSignal
**Date:** 06-12-2025
**Purpose:** Dedicated server for handling downloads and running a VPN client (not configured here) to tunnel traffic.
**VM ID:** 103

---

## 🛠️ Proxmox VM Configuration

This VM uses a **Shutdown Timeout** to ensure download processes are terminated gracefully.

| Section | Parameter | Value | Notes |
| :--- | :--- | :--- | :--- |
| **General** | VM ID | `103` | |
| | Name | `destiny` | |
| **OS** | Image | Ubuntu Server | |
| | Type | Linux | |
| **System** | Machine | `q35` | |
| | SCSI Controller | `VirtIO SCSI single` | |
| **Disk** | Size | `32 GB` | OS Drive |
| | Cache | `Write through` | |
| | Discard | **Checked** | |
| **CPU** | Sockets/Cores | 1 Socket / 2 Cores | |
| | Type | `host` | |
| **Memory** | RAM | `4096 MB` | |

### Options (Boot/Shutdown)

| Option | Value | Rationale |
| :--- | :--- | :--- |
| **Start at boot** | **Yes** | |
| **Startup Order** | `3` | Starts after DNS (Prometheus, Order 1) and the Management server/NAS (Order 2). |
| **Startup Delay** | Default (`0`) | |
| **Shutdown Timeout** | `180` | **CRITICAL:** Allows 3 minutes for running download clients/processes to save state before forcing shutdown. |

---

## 💾 Ubuntu Server Installation & Initial Setup

1.  **Installation:** Use the Ubuntu Server ISO with default settings.
2.  **Network:** Default (DHCP) - *Configure Static IP post-install.*
3.  **Storage:** Guided configuration (Default).
4.  **Profile:** Use `$username` and server name `destiny`.
5.  **Reboot:** Stop VM in Proxmox, remove ISO, start VM.

### 1. Post-Install VM Maintenance
```bash
# Update and Clean
sudo apt update && sudo apt upgrade -y
sudo apt clean && sudo apt autoremove && sudo apt autoclean
reboot now

# Disable Root Local Login
sudo passwd -l root
```

### 2. Create Directory Structure
```bash
sudo mkdir -p /drives         # For mounting the 1TB HDD (theseed)
sudo mkdir -p /docker/composefiles # For Docker configs
```

### 3. Network Configuration (Netplan)
Set a static IP using Netplan.

1.  Check interface name:
    ```bash
    ip a
    ```
2.  Edit configuration:
    ```bash
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```
3.  Paste configuration:
    ```yaml
    network:
      version: 2
      ethernets:
        enp6s18:
          dhcp4: no
          addresses: [$destiny-ip/24]
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

## 🔒 Security Hardening (Firewall & SSH)

### 1. UFW Firewall
Restrict access to the trusted **Midway Station** jump host.

| Command | Description |
| :--- | :--- |
| \`sudo ufw allow from $midway-station-ip to any port 22\` | Allow SSH from Midway Station only. |
| \`sudo ufw deny 22/tcp\` | Block all other SSH connections. |
| \`sudo ufw enable\` | Activate the firewall. |
| \`sudo ufw status verbose\` | Check firewall status. |

### 2. OpenSSH User Restriction
Only allow connections from specific users on the specific jump host.

1.  Edit the configuration:
    ```bash
    sudo nano /etc/ssh/sshd_config
    ```
2.  Add or modify the user restriction:
    ```ini
    AllowUsers $username-current-machine@$midway-station-ip
    ```
3.  Restart SSH service:
    ```bash
    sudo systemctl restart ssh
    ```

### 3. Fail2Ban
Whitelist the Midway Station IP.

1.  Edit jail config:
    ```bash
    sudo nano /etc/fail2ban/jail.local
    ```
2.  Add whitelist:
    ```ini
    [DEFAULT]
    ignoreip = 127.0.0.1/8 $midway-station-ip
    ```
3.  Restart service:
    ```bash
    sudo systemctl restart fail2ban && sudo systemctl status fail2ban
    ```

---

# 🗄️ Storage: Single Drive Preparation and Mounting

**Purpose:** Procedure for securely wiping, partitioning, and permanently mounting a single disk (e.g., 1TB HDD named `theseed`) to the VM.

---

## ⚠️ Part 1: Wipe and Format the Drive

**Target Device:** `/dev/sdb` (Check `lsblk` to verify this is the correct device ID before running!)

### 1. Securely Wipe and Clean the Drive
This step removes existing signatures and the partition table header.


# 1. Wipe file system signatures
```bash
sudo wipefs -a /dev/sdb
```

# 2. Zero out the first 100MB of the drive (optional, but ensures clean start)
```bash
sudo dd if=/dev/zero of=/dev/sdb bs=1M count=100
```

### 2. Partition and Format the Drive
Create a **GPT** partition table and an **ext4** partition across the entire disk.


# 1. Start parted and create a GPT label
```bash
sudo parted /dev/sdb mklabel gpt
```

# 2. Create the primary partition (ext4, 0% to 100%)
```bash
sudo parted -a opt /dev/sdb mkpart primary ext4 0% 100%
```

# 3. Format the new partition (the partition will be /dev/sdb1)
```bash
sudo mkfs.ext4 /dev/sdb1
```

---

## 💾 Part 2: Mount and Configure Persistence

**Target Volume:** Single 1TB Volume (`theseed`)

### 1. Identify UUID and Create Mount Point

1.  Check the UUID of the new partition (assuming the partition is `/dev/sdb1`):
    ```bash
    sudo blkid /dev/sdb1
    ```
2.  Create the destination mount point:
    ```bash
    sudo mkdir -p /drives/theseed
    ```

### 2. Make Mount Persistent (`/etc/fstab`)

**CRITICAL:** Use the **UUID** found from `sudo blkid` for stable mounting.

1.  Edit the `fstab` configuration file:
    ```bash
    sudo nano /etc/fstab
    ```
2.  Add the new entry (replace the UUID with the value from step 1):
    ```fstab
    # 1TB drive mounted in /drives/theseed
    UUID=7d58bc88-1128-44ad-86a6-c7a27efd24e5 /drives/theseed ext4 defaults 0 0
    ```

### 3. Reload and Verify
Reload the daemon and mount all entries listed in `fstab`.

```bash
sudo systemctl daemon-reload
sudo mount -a
ls /drives/*/ # Verify contents
```
