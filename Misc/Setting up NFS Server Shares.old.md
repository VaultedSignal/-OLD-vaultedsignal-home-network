# VS Home Network - Setting up NFS Server Shares

**VM Host:** VM 102 (Atlantis, the NAS)
**Purpose:** Export local drive mounts (`/drives/aincrad`, `/drives/alfheim`) via Network File System (NFS) to clients on the local subnet.

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
| `drives/aincrad` | `$lan-ip/24` | `(rw,sync,no_subtree_check)` | Read/Write access for the anime drive. |
| `drives/alfheim` | `$lan-ip/24` | `(rw,sync,no_subtree_check)` | Read/Write access for the general data drive. |

```bash
/drives/aincrad $lan-ip/24(rw,sync,no_subtree_check)
/drives/alfheim $lan-ip/24(rw,sync,no_subtree_check)
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

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
