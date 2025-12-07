# 🤖 Portainer with Docker Compose

**Service:** Portainer Community Edition (CE)
**File:** `portainer-compose.yaml`
**Purpose:** Provides a web interface for managing your Docker containers, images, volumes, and networks.

---

## 1 Deployment Steps (On Your VM)

### A. Create Data Volume Directory

First, ensure you are in the correct directory (e.g., `/docker/portainer`) and create the necessary volume folder.

```bash
# Create directory for Portainer data
sudo mkdir -p /docker/portainer

# Change directory
cd /docker/portainer

# Create the compose file
sudo nano portainer-compose.yaml
```

### B. Run the Stack

Paste the YAML content below into the file and save it. Then, deploy the stack:

```bash
# Run the Portainer stack in detached mode
sudo docker compose -f portainer-compose.yaml up -d
```

## 2️ Portainer Compose File (`portainer-compose.yaml`)

This YAML file defines the Portainer container, ensuring it runs on boot (`restart: always`), is persistent (`volumes`), and exposes the management port.

```yaml
#this is ann example see portainer-compose.yaml for current running version.
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    
    ports:
      # Access Portainer UI securely via HTTPS on port 9443
      - 9443:9443 
      # Optional: Port for HTTP redirect (only needed if accessing over HTTP/8000)
      # - 8000:8000 
      
    volumes:
      # Data Persistence: Stores Portainer configuration
      - /docker/portainer/data:/data
      # Docker Socket: Required for Portainer to manage the local Docker environment
      - /var/run/docker.sock:/var/run/docker.sock
```

---

## 3 Verification

Once the stack is running, you can access the UI via your web browser:

1. Check the container status:

    ```bash
    sudo docker ps -a
    ```

2.  Access the UI: **https://$vm-ip:9443/** (e.g., `https://$midway-station-ip:9443/`)

The first time you connect, you will be prompted to create your admin password.

## 4. Post-Deployment Setup

## 1. Firewall Configuration (UFW)

These UFW rules must be applied to the **Prometheus VM** to allow DNS, web administration, DHCP (if used), and NTP traffic only from your local network.

**Note:** Pi-hole is designed for internal use. These rules allow traffic from the LAN (192.168.0.0/16 is an example range) but block external access for security.

### UFW Rules

```bash
# Allow Web Interface (HTTP/HTTPS)
sudo ufw allow from $lan-ip/24 to any port 9443 proto tcp
```
