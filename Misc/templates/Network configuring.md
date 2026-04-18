# VS Home Network - Network configuring

```bash
# Identify network interface
ip addr show

# Backup original configuration
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak

# Edit netplan configuration
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Network Configuration**:

```yaml
network:
  version: 2
  ethernets:
    ens18:  # Replace with your interface name
      dhcp4: no
      addresses:
        - 192.168.1.50/24  # Replace with desired IP
      routes:
        - to: default
          via: 192.168.2.254  # Gateway (router)
      nameservers:
        addresses:
          - 192.168.1.253   # Prometheus (Pi-hole)
#         - 192.168.1.252   # 2nd pi hole server for redundancy

```

**Apply configuration**:

```bash
# Test configuration (will auto-revert in 120s if you lose connection)
sudo netplan try

# If successful, press Enter to accept
# Or apply directly
sudo netplan apply

# Verify configuration
ip addr show
ping -c 4 1.1.1.1
ping -c 4 google.com
```

## Configure DNS Resolution

```bash
# Verify DNS configuration
resolvectl status

# Test DNS resolution
nslookup google.com
nslookup google.com 192.168.1.253 # Test Pi-hole specifically
```

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
