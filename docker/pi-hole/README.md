# VS Home Network - Pi-hole Network Ad Blocker

A network-wide DNS-based ad blocking and filtering solution running on Docker.

## Overview

Pi-hole acts as a DNS sinkhole that blocks advertisements and tracking domains at the network level before they reach your devices. This deployment runs on VM 999 (Prometheus) and provides ad blocking for all devices on the network without requiring individual software installation.

**Host:** Prometeus
**Purpose:**
**Official Documentation:** [pi-hole Official Documentation](https://github.com/pi-hole/pi-hole/#one-step-automated-install)
**File:** [`pihole-compose.yaml`](pihole-compose.yaml)

## Architecture

Pi-hole intercepts DNS queries from all network devices and:

1. Checks if the domain is on a blocklist
2. If blocked, returns a null response (ad doesn't load)
3. If allowed, forwards the query to upstream DNS servers (Cloudflare)
4. Caches responses for faster subsequent queries

## Technology Stack

### Core Infrastructure

- **Container Platform**: Docker
- **DNS Server**: Pi-hole (Official Docker Image)
- **Upstream DNS**: Cloudflare (1.1.1.1, 1.1.1.2)

## Features

- 🛡️ Network-wide ad blocking
- 📊 Real-time statistics dashboard
- 🌐 DNS filtering and blacklist management
- 📝 Query logging and analytics
- ⚡ Fast DNS resolution with caching
- 🔒 HTTPS web interface support
- 🎯 Customizable blocklists and whitelists

## Storage Structure

```txt
/docker/pihole/
          └── etc-pihole/         # Pi-hole configuration, databases, and blocklists
```

## Setup & Configuration

### Prerequisites

- Docker and Docker Compose installed on Prometheus VM
- Static IP address assigned to Prometheus VM
- Port 53 (DNS) available on the host

### Environment Variables

Create a `.env` file in the same directory as `pihole-compose.yml`:

```env
passwd=your_secure_password
```

### Installation

1. Create the compose file

```bash
sudo nano  /docker/composefiles/pihole-compose.yaml
```

2. Copy the [pihole-compose.yaml](pihole-compose.yaml)
3. Set up your `.env` file with credentials (e.g. [.env](.env))

```bash
sudo nano /docker/composefiles/.env
```

4. Start the container:

```bash
sudo docker compose -f /docker/composefiles/pihole-compose.yaml up -d
```

5. Access the services via [`http://192.168.2.254`](http://192.168.2.254)

## Configuration Notes

### DNS Configuration

| Setting | Value |
| --------- | ------- |
| **Listening Mode** | ALL (required for Docker bridge network) |
| **Upstream DNS** | Cloudflare (1.1.1.1, 1.1.1.2) |
| **Timezone** | Europe/Amsterdam |

## Firewall Configuration

Apply these UFW rules on the Prometheus VM to allow Pi-hole traffic from your local network only:

```bash
# Install UFW (if not already installed)
sudo apt install ufw -y

# Allow Web Interface from local network
sudo ufw allow from 192.168.2.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 443 proto tcp

# Allow DNS Queries
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# Optional: Allow DHCP (only if Pi-hole is your DHCP server)
# sudo ufw allow 67/tcp
# sudo ufw allow 67/udp

# Optional: Allow NTP
sudo ufw allow 123/udp

# Enable firewall
sudo ufw enable

# Verify configuration
sudo ufw status verbose
```

**Note:** Replace `192.168.2.0/24` with your actual local network subnet.

## Network Setup

### Router Configuration

To enable network-wide ad blocking, configure your router to use Pi-hole as the DNS server:

| Setting | Value |
|---------|-------|
| **Primary DNS** | Prometheus IP address |
| **Secondary DNS** | Prometheus IP address or and better 2nd instance of pihole for redundancy |

**Important:** Using the same IP for both primary and secondary DNS ensures all queries go through Pi-hole. Using an external DNS as secondary would bypass Pi-hole filtering.

### Alternative: Per-Device Configuration

Instead of router-level configuration, you can set DNS on individual devices:

- **Windows**: Network Settings > Change Adapter Options > IPv4 Properties
- **macOS**: System Preferences > Network > Advanced > DNS
- **Linux**: `/etc/resolv.conf` or NetworkManager settings
- **Mobile**: WiFi Settings > Configure DNS > Manual

## Web Interface Setup

Access the Pi-hole admin panel at:

- **HTTP**: [`http://192.168.253/admin`](http://192.168.253/admin)
- **HTTPS**: [`https://192.168.2.253/admin`](http://192.168.253/admin)

### Initial Configuration

1. Log in with the password set in your compose file
2. Complete the setup wizard if prompted
3. Verify DNS is working in Dashboard

### Recommended Blocklists

Navigate to **Adlists** and add these comprehensive blocklists:

| Blocklist | URL | Purpose |
| ----------- | ----- | --------- |
| **Hagezi Multi** | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/multi.txt` | General ad blocking |
| **Hagezi Popup Ads** | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/popupads.txt` | Popup and overlay ads |
| **Hagezi TIF** | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/tif.txt` | Threat Intelligence Feeds |
| **Hagezi Fake** | `https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/fake.txt` | Fake sites and scams |

After adding blocklists:

1. Go to **Tools** > **Update Gravity**
2. Click **Update** to apply the new lists
3. Monitor the dashboard for blocking statistics

## Ports & Access

| Port | Protocol | Purpose |
| ------ | ---------- | --------- |
| 53 | TCP/UDP | DNS queries |
| 80 | TCP | Web interface (HTTP) |
| 443 | TCP | Web interface (HTTPS) |
| 67 | UDP | DHCP server (optional) |
| 123 | UDP | NTP server (optional) |

## Security notes

- Container runs with elevated capabilities (NET_ADMIN, SYS_TIME)
- Web interface is password-protected
- Firewall rules restrict access to local network only
- HTTPS available for encrypted web interface access
- No external DNS queries logged by default

## Maintenance

### Update Container

```bash
cd /docker/composefiles
sudo docker compose -f pihole-compose.yaml pull
sudo docker compose -f pihole-compose.yaml up -d
```

### Update Blocklists

```bash
# Via CLI
sudo docker exec pihole pihole -g

# Or via Web Interface
# Go to Tools > Update Gravity > Update
```

### Backup Configuration

```bash
# Backup Pi-hole settings
sudo tar -czf pihole-backup-$(date +%Y%m%d).tar.gz /docker/pihole/etc-pihole
```

### View Logs

```bash
# Container logs
sudo docker logs pihole
sudo docker logs -f pihole  # Follow mode

# Pi-hole query logs
sudo docker exec pihole pihole -t
```

### Restart Container

```bash
sudo docker restart pihole
```

## Usage & Management

### Whitelisting Domains

If a legitimate site is blocked:

1. Go to **Whitelist** in the web interface
2. Add the domain (e.g., `example.com`)
3. Click **Add to Whitelist**

### Blacklisting Domains

To block additional domains:

1. Go to **Blacklist** in the web interface
2. Add the domain
3. Optionally use wildcards: `*.ads.example.com`

### Query Log

View real-time DNS queries:

- Navigate to **Query Log** in the web interface
- Filter by domain, client, or status
- Whitelist/blacklist domains directly from the log

### Statistics Dashboard

Monitor Pi-hole performance:

- **Total Queries**: All DNS requests processed
- **Queries Blocked**: Ads and trackers stopped
- **Percent Blocked**: Blocking efficiency
- **Top Domains**: Most queried domains
- **Top Clients**: Devices making most requests

## Troubleshooting

**Cannot access web interface?**

- Verify container is running: `sudo docker ps | grep pihole`
- Check firewall rules allow access from your IP
- Try accessing via HTTP instead of HTTPS

**DNS not resolving?**

- Verify port 53 is not in use by another service
- Check DNS settings on client devices
- Test DNS: `nslookup google.com prometheus-ip`

**Devices not using Pi-hole?**

- Verify router DNS settings are configured correctly
- Some devices may cache old DNS settings (reboot device)
- Check if device is using hardcoded DNS (8.8.8.8, etc.)

**Too many domains blocked?**

- Review and adjust blocklists in **Adlists**
- Whitelist specific domains causing issues
- Use Query Log to identify false positives

**Container won't start?**

- Check if port 53 is already in use: `sudo netstat -tulpn | grep :53`
- Disable systemd-resolved if conflicting: `sudo systemctl disable systemd-resolved`

## References

- [Pi-hole Official Documentation](https://docs.pi-hole.net/)
- [Pi-hole Docker Hub](https://hub.docker.com/r/pihole/pihole)
- [Pi-hole GitHub Repository](https://github.com/pi-hole/docker-pi-hole/)
- [Hagezi DNS Blocklists](https://github.com/hagezi/dns-blocklists)
- [More hagezi lists](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#pro)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
