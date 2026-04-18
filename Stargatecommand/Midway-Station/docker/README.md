# VS Home Network - Portainer Docker Management

A web-based management interface for Docker containers, images, volumes, and networks.

## Overview

Portainer Community Edition (CE) provides a user-friendly web interface for managing Docker environments. Instead of using command-line tools, you can monitor, deploy, and manage containers through an intuitive dashboard. This deployment allows for easy container management across your home network infrastructure.

**VM Host:** VM 101 midway-sation
**Purpose:** Docker container web-based management
**Reference:** [Portainer Official Documentation](https://docs.portainer.io/)
**File:** [`portainer-compose.yaml`](portainer-compose.yaml)

## Architecture

Portainer runs as a privileged container with access to the Docker socket, allowing it to:

- Monitor all containers on the host
- Start, stop, and restart containers
- View logs and statistics
- Deploy new containers
- Manage Docker resources (networks, volumes, images)

## Technology Stack

### Core Infrastructure

- **Container Platform**: Docker
- **Management Interface**: Portainer CE (Official Docker Image)
- **Access Method**: HTTPS Web Interface
- **Deployment**: Docker Compose

## Features

- 🐳 Visual Docker container management
- 📊 Real-time resource monitoring
- 🚀 Quick container deployment from templates
- 📦 Image management and registry integration
- 💾 Volume and network management
- 👥 Multi-user access control
- 🔐 Secure HTTPS access
- 📱 Responsive web interface

## Storage Location

```txt
/docker/portainer/
  └── data/              # Portainer database, settings, and configuration
```

## Setup & Configuration

### Prerequisites

- Docker and Docker Compose installed
- Port 9443 available on the host
- Sufficient permissions to access Docker socket

### Installation

1. Create the compose file

```bash
sudo nano /docker/composefiles/portainer.yaml
```

2. Copy the [portainer.yaml](portainer.yaml)
3. Start the stack:

```bash
sudo docker compose -f /docker/composefiles/portainer.yaml up -d
```

4. Access the services via [`http://192.168.2.201:9443`](http://192.168.2.201:9443)

## Configuration Notes

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `/docker/portainer/data` | `/data` | Portainer configuration and settings |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker API access (required) |

### Important Notes

- **Docker Socket Access**: Portainer requires access to `/var/run/docker.sock` to manage Docker
- **Privileged Access**: This gives Portainer full control over Docker on the host
- **Restart Policy**: Set to `always` to ensure Portainer survives reboots

## Firewall Configuration

Apply these UFW rules to allow HTTPS access from your local network:

```bash
# Allow Portainer web interface from local network
sudo ufw allow from 192.168.2.0/24 to any port 9443 proto tcp # Use correct lan

# Verify configuration
sudo ufw status verbose
```

## Initial Setup

### First-Time Access

1. Navigate to `https://192.168.2.253:9443` in your web browser
2. Accept the self-signed certificate warning (first time only)
3. login to admin account:
   - **Username**: admin (default)
   - **Password**: Set a strong password (minimum 12 characters)
4. Click **Create user**

### Connect to Docker Environment

After creating your admin account:

1. Select **Get Started** or **Local** environment
2. Portainer will automatically connect to the local Docker instance
3. You'll be taken to the main dashboard

### Dashboard Overview

The Portainer dashboard displays:

- **Containers**: Running and stopped containers
- **Images**: Downloaded Docker images
- **Volumes**: Persistent storage volumes
- **Networks**: Docker networks
- **Stacks**: Docker Compose deployments

## Usage

### Managing Containers

**View Containers:**

- Go to **Containers** in the sidebar
- See all running and stopped containers
- View resource usage, status, and uptime

**Container Actions:**

- **Start/Stop**: Control container state
- **Restart**: Restart a container
- **Kill**: Force stop a container
- **Logs**: View container logs in real-time
- **Inspect**: View detailed container configuration
- **Stats**: Monitor CPU, memory, and network usage
- **Console**: Access container shell

### Deploying New Containers

**From Template:**

1. Go to **App Templates**
2. Select a pre-configured application
3. Configure settings
4. Click **Deploy**

**From Docker Compose:**

1. Go to **Stacks** > **Add stack**
2. Paste your docker-compose.yml content
3. Configure environment variables if needed
4. Click **Deploy the stack**

**From Container Registry:**

1. Go to **Containers** > **Add container**
2. Enter image name (e.g., `nginx:latest`)
3. Configure ports, volumes, and environment variables
4. Click **Deploy the container**

### Managing Stacks

Portainer treats Docker Compose deployments as "Stacks":

- View all deployed stacks
- Stop/Start entire stacks
- Update stack configurations
- View stack logs
- Remove stacks completely

### Image Management

- **Pull Images**: Download images from Docker Hub or registries
- **Remove Images**: Delete unused images to free space
- **Tag Images**: Add custom tags to images
- **Export/Import**: Backup and restore images

### Volume Management

- **Create Volumes**: Create new Docker volumes
- **Browse**: View volume contents (if supported)
- **Remove**: Delete unused volumes
- **Backup**: Export volume data

### Network Management

- **View Networks**: See all Docker networks
- **Create Networks**: Define custom networks
- **Connect Containers**: Attach containers to networks
- **Remove Networks**: Delete unused networks

## Ports & Access

| Port | Protocol | Purpose |
|------|----------|---------|
| 9443 | TCP | HTTPS Web Interface |
| 8000 | TCP | HTTP (optional, for edge agent communication) |

**Web Interface**: [`https://192.168.2.253:9443`](https://192.168.2.253:9443)

## Maintenance

### Update Portainer

```bash
cd /docker/portainer
sudo docker compose -f portainer-compose.yaml pull
sudo docker compose -f portainer-compose.yaml up -d
```

### Backup Configuration

```bash
# Backup Portainer data
sudo tar -czf portainer-backup-$(date +%Y%m%d).tar.gz /docker/portainer/data

# Restore from backup
sudo tar -xzf portainer-backup-YYYYMMDD.tar.gz -C /
```

### View Logs

```bash
# View container logs
sudo docker logs portainer

# Follow logs in real-time
sudo docker logs -f portainer
```

### Restart Portainer

```bash
sudo docker restart portainer
```

## Troubleshooting

**Cannot access web interface?**

- Verify container is running: `sudo docker ps | grep portainer`
- Check firewall rules allow access from your IP
- Try accessing via IP address instead of hostname
- Verify port 9443 is not used by another service

**"Cannot connect to Docker daemon" error?**

- Verify Docker socket is mounted correctly
- Check Docker service is running: `sudo systemctl status docker`
- Ensure user has Docker permissions

**Forgot admin password?**

- Stop Portainer: `sudo docker stop portainer`
- Remove password file: `sudo rm /docker/portainer/data/portainer.db`
- Start Portainer: `sudo docker start portainer`
- Create new admin account

**Containers not showing up?**

- Verify Docker socket mount in compose file
- Check Portainer logs for errors
- Ensure Portainer has permission to access Docker socket

**SSL certificate warnings?**

- This is normal for self-signed certificates
- You can safely proceed (add exception in browser)
- For production, consider using a proper SSL certificate

## Security Considerations

- **Full Docker Access**: Portainer has complete control over Docker
- **Admin Password**: Use a strong, unique password
- **Network Restriction**: Limit access to trusted networks only
- **HTTPS Only**: Always use HTTPS (port 9443) for secure access
- **Regular Updates**: Keep Portainer updated for security patches
- **User Management**: Create separate users with limited permissions if needed

## Advanced Features

### Multi-Environment Management

Portainer can manage multiple Docker environments:

- Local Docker instances
- Remote Docker hosts
- Docker Swarm clusters
- Kubernetes clusters (with Portainer Business Edition)

### Edge Agent

Deploy Portainer agents on remote systems for centralized management:

1. Go to **Environments** > **Add environment**
2. Select **Edge Agent**
3. Follow deployment instructions for remote host

### Registry Management

Connect to container registries:

- Docker Hub
- Private registries
- GitLab Registry
- Azure Container Registry
- Custom registries

### Custom Templates

Create your own application templates:

1. Go to **App Templates** > **Custom Templates**
2. Define container/stack configuration
3. Share templates across your environment

## Performance

- **Memory Usage**: ~50-100 MB
- **CPU Usage**: Minimal (< 5%)
- **Storage**: < 500 MB for data
- **Startup Time**: < 5 seconds

## References

- [Portainer Official Documentation](https://docs.portainer.io/)
- [Portainer Docker Hub](https://hub.docker.com/r/portainer/portainer-ce)
- [Portainer GitHub Repository](https://github.com/portainer/portainer)
- [Portainer Community Forums](https://community.portainer.io/)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
