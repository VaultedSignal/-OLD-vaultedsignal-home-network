# 📤 Setting up NFS Client Shares

**Purpose:** Configure a client VM to permanently mount storage volumes exported via NFS from the central NAS/File Server Atlantis.

---

## 1. 🛠️ Install NFS Client and Create Mount Points

On the **client VM** (the machine that needs to access the shares), install the necessary client utilities and create the local directories where the remote shares will appear.

```bash
# Install the NFS client utilities
sudo apt update
sudo apt install nfs-common -y

# Create local mount points for the remote shares
sudo mkdir -p /drives/aincrad
sudo mkdir -p /drives/alfheim
```

---

## 2. 🧪 Test Mount the NFS Shares

Temporarily mount the remote shares to verify that the connection works and permissions are correct before making the entries permanent.

```bash
# Test mount the 'aincrad' share (Replace IP with the NFS Server's IP)
sudo mount $atlantis-ip:/drives/aincrad /drives/aincrad

# Test mount the 'alfheim' share (Replace IP with the NFS Server's IP)
sudo mount $atlantis-ip:/drives/alfheim /drives/alfheim
```

## 3. 💾 Make Mounts Persistent (`/etc/fstab`)

To ensure the shares are mounted automatically after every reboot, add the entries to the File System Table (`/etc/fstab`).

1. Edit the `fstab` file:

```bash
sudo nano /etc/fstab
```

2. Add the following lines:

```bash
# NFS Mounts from $atlantis-ip (atlantis media server)
$atlantis-ip:/drives/aincrad /drives/aincrad nfs defaults 0 0
$atlantis-ip:/drives/alfheim /drives/alfheim nfs defaults 0 0
```

3. Reload the daemon and verify the mounts:

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Mount all entries specified in fstab (this will remount the test mounts)
sudo mount -a

# Check the mounts
df -h | grep nfs
```

# 📤 Setting up NFS Server Shares

**VM Host:** VM 103 (Destiny, Download server)
**Purpose:** Export local drive mounts (`/drives/theseed`) via Network File System (NFS) to clients on the local subnet.

---

## 1. 🛠️ Install NFS Kernel Server

On the VM, install the necessary package to enable the system to serve NFS shares.

```bash

# Update package list
sudo apt update
# Install the NFS server package
sudo apt install nfs-kernel-server -y
```

---

## 2. 📝 Configure NFS Exports

Edit the `/etc/exports` configuration file to define which directories are shared and what access permissions are granted to the network.

### A. Edit Configuration File

```bash
sudo nano /etc/exports
```

### B. Add Share Entries

Add the following lines to the end of the file. Replace the example subnet `$lan-ip/24` with your actual local network range if different.

| Share Path | Client Access | Options | Description |
| :--- | :--- | :--- | :--- |
| `drives/theseed` | `$lan-ip/24` | `(rw,sync,no_subtree_check)` | download drive. |

```bash
/drives/theseed $lan-ip/24(rw,sync,no_subtree_check)
```

---

## 3. 🚀 Apply and Restart Service

Apply the new export settings and ensure the NFS server service is running and configured to start on boot.

```bash
# Apply new settings without restarting the service (-r = reload, -a = all)
sudo exportfs -ra
# Restart the NFS kernel server service
sudo systemctl restart nfs-kernel-server
# Verify the shares are being exported
sudo exportfs -v
```

# Update firewall

Allow access to the essential NFS ports from your local network range ($lan-ip$/24).

```bash
# 1. Allow Port 111 (RPC/Portmapper) for TCP and UDP
sudo ufw allow from $lan-ip/24 to any port 111 proto tcp
sudo ufw allow from $lan-ip/24 to any port 111 proto udp
# 2. Allow Port 2049 (NFS Data Transfer) for TCP and UDP
sudo ufw allow from $lan-ip/24 to any port 2049 proto tcp
sudo ufw allow from $lan-ip/24 to any port 2049 proto udp
# 3. Apply the changes immediately
sudo ufw reload
# 4. Verify the new rules are active
sudo ufw status verbose
```
