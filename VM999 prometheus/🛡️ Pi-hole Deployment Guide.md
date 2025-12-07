# 🛡️ Pi-hole Deployment Guide (VM 999: Prometheus)

**Purpose:** Deploy Pi-hole as a Docker container on the Prometheus VM to provide network-wide DNS-based ad blocking and filtering.
**Method:** Docker Compose
**Container Host:** VM 999 (Prometheus)

---

## 1. Firewall Configuration (UFW)

These UFW rules must be applied to the **Prometheus VM** to allow DNS, web administration, DHCP (if used), and NTP traffic only from your local network.

**Note:** Pi-hole is designed for internal use. These rules allow traffic from the LAN (192.168.0.0/16 is an example range) but block external access for security.

### UFW Rules
```bash
# Install UFW (if not already installed on Debian/Ubuntu)
sudo apt install ufw -y

# Allow Web Interface (HTTP/HTTPS)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow DNS Queries (Standard for Pi-hole)
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# Allow DHCP (Needed ONLY if Pi-hole is your DHCP server)
sudo ufw allow 67/tcp
sudo ufw allow 67/udp

# Allow NTP (Time Synchronization, standard)
sudo ufw allow 123/udp

# Enable the firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## 2. Docker Compose File (`pi-hole-compose.yaml`)

This configuration uses your specified settings, including time zone, password, and upstream DNS servers.

### File Location and Creation
```bash
# Navigate to the correct directory on Prometheus VM
cd /docker/composefiles

# Create the compose file
sudo nano pi-hole-compose.yaml
```

### Compose YAML Content
```yaml
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    hostname: prometheus
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      # DNS Ports
      - "53:53/tcp"
      - "53:53/udp"
      # Default HTTP Port (Web Interface)
      - "80:80/tcp"
      # Default HTTPs Port (Web Interface)
      - "443:443/tcp"
      # Uncomment the line below if you are using Pi-hole as your DHCP server
      # - "67:67/udp"
      # Uncomment the line below if you are using Pi-hole as your NTP server
      # - "123:123/udp"
    environment:
      # Timezone: Europe/Amsterdam
      TZ: 'Europe/Amsterdam'
      # Web Interface Password
      FTLCONF_webserver_api_password: '$password'
      # DNS Listening Mode: 'ALL' required when using Docker's bridge network
      FTLCONF_dns_listeningMode: 'ALL'
      # Upstream DNS server(s)
      FTLCONF_dns_upstreams: 1.1.1.1;1.1.1.2
    # Volumes store your data between container upgrades
    volumes:
      # Persistence for Pi-hole's databases and common configuration file
      - './etc-pihole:/etc/pihole'
    cap_add:
      # NET_ADMIN is required if using Pi-hole as your DHCP server
      - NET_ADMIN
      # SYS_TIME is required if using Pi-hole as your NTP client
      - SYS_TIME
      # SYS_NICE is optional for priority setting
      - SYS_NICE
    restart: unless-stopped
```

---

## 3. Deployment and Verification

### A. Start the Container
```bash
# Start the Pi-hole container in detached mode
sudo docker compose -f pi-hole-compose.yaml up -d
```

### B. Verify Status
```bash
sudo docker ps -a | grep pihole
```

---

## 4. Post-Deployment Setup

### A. Add Blocklists
1.  Access the Pi-hole WebUI: `http://$prometheus-ip/admin` (or HTTPS on 443).
2.  Log in using the password set in the YAML.
3.  Go to **Adlists** and add the following URLs:

| Source | URL |
| :--- | :--- |
| Hagezi Multi | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/multi.txt` |
| Hagezi Popup Ads | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/popupads.txt` |
| Hagezi TIF | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/tif.txt` |
| Hagezi Fake | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/fake.txt` |

4.  Go to **Tools** > **Update Gravity** to apply the new lists.

### B. Router/Modem Configuration
To enable network-wide filtering, set the Pi-hole's static IP as the primary DNS server in your router/modem settings.

| Setting | Value |
| :--- | :--- |
| **Primary DNS** | `$prometheus-ip` |
| **Secondary DNS** | `$prometheus-ip` |

**Note:** Using the Pi-hole's IP for both primary and secondary DNS ensures all traffic goes through Pi-hole, maintaining filtering even if the first query fails.
