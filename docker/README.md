# Docker Engine Installation

Complete installation guide for Docker Engine, CLI, and Containerd on Debian-based Linux distributions.

## Overview

This guide covers the installation of Docker Engine from the official Docker repository, ensuring you get the latest stable version with proper package signing and verification. Docker enables containerization, allowing you to run isolated applications in lightweight containers across your infrastructure.

## Technology Stack

- **Container Runtime**: Docker Engine (Community Edition)
- **CLI Tool**: Docker CLI
- **Container Runtime**: Containerd
- **Build Tools**: Docker Buildx Plugin
- **Orchestration**: Docker Compose Plugin
- **Supported OS**: Linux distributions

## Features

- 🐳 Latest stable Docker Engine
- 📦 Official Docker repository packages
- 🔒 GPG-signed package verification
- ⚡ Native Docker Compose support (plugin)
- 🏗️ BuildKit support via Buildx
- 👤 Non-root user configuration
- 🔄 Automatic updates via apt

## Prerequisites

- Linux distribution (Ubuntu 20.04+, Debian 11+)
- Root or sudo access
- Active internet connection
- x86_64/amd64 architecture (or arm64 for ARM-based systems)

## Installation

### Step 1: Update System and Install Dependencies

Install required packages for managing repositories over HTTPS:

```bash
# Update package index
sudo apt update

# Install prerequisite packages
sudo apt install ca-certificates curl -y
```

### Step 2: Add Docker's GPG Key

Docker signs all packages for security. Add the GPG key to verify package authenticity:

```bash
# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# Set proper permissions
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

**Note**: For Debian, replace `ubuntu` with `debian` in the URL.

### Step 3: Add Docker Repository

Configure the Docker stable repository:

```bash
# Add Docker repository to sources list
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update package index with new repository
sudo apt update
```

**What this does**:

- Automatically detects your distribution codename (e.g., `jammy`, `focal`)
- Adds Docker's stable channel
- Links to the GPG key for package verification

### Step 4: Install Docker Engine

Install Docker and all required components:

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

**Packages installed**:

- **docker-ce**: Docker Community Edition engine
- **docker-ce-cli**: Command-line interface for Docker
- **containerd.io**: Container runtime
- **docker-buildx-plugin**: Enhanced build capabilities
- **docker-compose-plugin**: Compose V2 (native plugin)

### Step 5: Enable Non-Root Access

Allow your user to run Docker commands without sudo:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply the group change to current session
newgrp docker

# Or log out and log back in for permanent effect
```

**Important**: After adding yourself to the docker group, you must either:

- Log out and log back in, OR
- Run `newgrp docker` in your current terminal

## Verification

### Test Docker Installation

Run the hello-world container to verify installation:

```bash
docker run hello-world
```

**Expected output**:

```txt
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### Check Docker Version

```bash
# Docker Engine version
docker --version

# Detailed Docker information
docker version

# Docker Compose version
docker compose version
```

### Verify Docker Service Status

```bash
# Check if Docker daemon is running
sudo systemctl status docker

# Enable Docker to start on boot
sudo systemctl enable docker
```

## Post-Installation Configuration

### System Service Management

```bash
# Start Docker service
sudo systemctl start docker

# Stop Docker service
sudo systemctl stop docker

# Restart Docker service
sudo systemctl restart docker

# Enable Docker to start on boot (usually already enabled)
sudo systemctl enable docker
```

### Configure Docker to Use Different Storage Location

If you need to move Docker's data directory:

```bash
# Stop Docker
sudo systemctl stop docker

# Edit daemon configuration
sudo nano /etc/docker/daemon.json
```

Add the following:

```json
{
  "data-root": "/new/path/to/docker"
}
```

```bash
# Restart Docker
sudo systemctl restart docker
```

### Configure Docker Logging

Limit log sizes to prevent disk space issues:

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

## Basic Docker Commands

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Start a container
docker start container_name

# Stop a container
docker stop container_name

# Remove a container
docker rm container_name

# View container logs
docker logs container_name

# Follow container logs in real-time
docker logs -f container_name
```

### Image Management

```bash
# List images
docker images

# Pull an image from Docker Hub
docker pull image_name:tag

# Remove an image
docker rmi image_name

# Build an image from Dockerfile
docker build -t image_name:tag .

# Search for images on Docker Hub
docker search nginx
```

### Docker Compose Commands

```bash
# Start services defined in docker-compose.yml
docker compose up -d

# Stop services
docker compose down

# View running services
docker compose ps

# View logs
docker compose logs -f

# Pull latest images
docker compose pull

# Restart services
docker compose restart
```

### System Management

```bash
# View Docker disk usage
docker system df

# Remove unused containers, images, networks
docker system prune

# Remove everything including volumes (use with caution!)
docker system prune -a --volumes

# Display system-wide information
docker info
```

## Useful Resources

### Official Docker Image Repositories

- **Docker Hub**: [https://hub.docker.com](https://hub.docker.com)
- **LinuxServer.io**: [https://docs.linuxserver.io/images-by-category/](https://docs.linuxserver.io/images-by-category/) - Extensive collection of well-maintained container images
- **GitHub Container Registry**: [https://ghcr.io](https://ghcr.io)
- **Quay.io**: [https://quay.io](https://quay.io)

### Popular Container Images

| Category | Images |
|----------|--------|
| **Web Servers** | nginx, apache, caddy |
| **Databases** | mysql, postgresql, mongodb, redis |
| **Media** | jellyfin, plex, emby |
| **Networking** | pihole, nginx-proxy-manager, traefik |
| **Automation** | sonarr, radarr, prowlarr, bazarr |
| **Development** | node, python, golang, nginx |

## Troubleshooting

**Docker command not found after installation?**

```bash
# Verify Docker is installed
which docker

# Check if Docker service is running
sudo systemctl status docker

# Ensure /usr/bin is in your PATH
echo $PATH
```

**Permission denied when running Docker commands?**

```bash
# Verify you're in the docker group
groups $USER

# If not, add yourself and reload
sudo usermod -aG docker $USER
newgrp docker
```

**Docker daemon not starting?**

```bash
# Check Docker service status
sudo systemctl status docker

# View detailed logs
sudo journalctl -xeu docker.service

# Check for port conflicts
sudo netstat -tulpn | grep docker
```

**Cannot connect to Docker daemon?**

```bash
# Verify Docker socket exists
ls -l /var/run/docker.sock

# Check socket permissions
sudo chmod 666 /var/run/docker.sock  # Temporary fix

# Restart Docker service
sudo systemctl restart docker
```

**Out of disk space?**

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# Remove specific items
docker container prune  # Remove stopped containers
docker image prune -a   # Remove unused images
docker volume prune     # Remove unused volumes
```

**Repository not found errors?**

```bash
# Verify repository is added correctly
cat /etc/apt/sources.list.d/docker.sources

# Update package index
sudo apt update

# Try reinstalling
sudo apt remove docker-ce docker-ce-cli containerd.io
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

## Security Considerations

- **Root Access**: Docker daemon runs as root; be cautious with containers
- **Docker Group**: Members of docker group have effective root access
- **Image Trust**: Only use images from trusted sources
- **Updates**: Regularly update Docker for security patches
- **Network Exposure**: Be careful exposing container ports to the internet
- **Secrets**: Never hardcode passwords in Dockerfiles or compose files

## Maintenance

### Update Docker

Docker updates automatically via apt:

```bash
# Update package index
sudo apt update

# Upgrade Docker packages
sudo apt upgrade docker-ce docker-ce-cli containerd.io
```

### Uninstall Docker

If you need to remove Docker completely:

```bash
# Stop Docker service
sudo systemctl stop docker

# Remove Docker packages
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Remove Docker data (optional - this deletes all containers, images, volumes)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove configuration
sudo rm -rf /etc/docker
```

## Next Steps

After installing Docker, you can:

1. Deploy Portainer for web-based container management
2. Set up Docker Compose stacks for multi-container applications
3. Configure reverse proxy with Nginx Proxy Manager or Traefik
4. Implement monitoring with cAdvisor or Prometheus
5. Set up automated backups for containers and volumes

## References

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Engine Installation](https://docs.docker.com/engine/install/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Hub](https://hub.docker.com/)
- [LinuxServer.io Images](https://docs.linuxserver.io/images-by-category/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

*Part of the SGC Home Network infrastructure project**
