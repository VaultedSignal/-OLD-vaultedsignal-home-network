# VS Home Network - Portainer Agent - Remote Management

Deploy Portainer Agent on remote Docker hosts for centralized management through your main Portainer server.

**Purpose:** Docker container web-based management
**Reference:** [Portainer Official Documentation](https://docs.portainer.io/admin/environments/add/docker/agent)

## Overview

The Portainer Agent is a lightweight container that runs on remote Docker hosts, enabling them to be managed from a central Portainer instance. This allows you to control multiple Docker environments from a single web interface without installing full Portainer on each host.

## Architecture

```txt
┌─────────────────────┐
│  Midway Station     │
│  (Portainer CE)     │
│  Port: 9443         │
└──────────┬──────────┘
           │
           │ Manages via Port 9001
           │
    ┌──────┴──────┬──────────────┐
    │             │              │
┌───▼────┐   ┌───▼────┐    ┌───▼────┐
│Atlantis│   │ Orion  │    │ Other  │
│ Agent  │   │ Agent  │    │ Hosts  │
└────────┘   └────────┘    └────────┘
```

## Technology Stack

- **Agent Software**: Portainer Agent (Official Docker Image)
- **Container Platform**: Docker
- **Communication Port**: 9001
- **Central Management**: Portainer CE (running on Midway Station)

### Core Infrastructure

- **Main Portainer server**: midway-station

## Features

- 🌐 Centralized multi-host Docker management
- 🔒 Secure agent-to-server communication
- 📊 Real-time monitoring of remote hosts
- 🚀 Deploy containers across multiple hosts from one interface
- 💾 Access to remote volumes and networks
- 🔄 Automatic reconnection on network issues
- ⚡ Lightweight resource footprint

## Storage Location

```txt
/docker/portainer-agent/
  └── portainer-agent-compose.yaml    # Agent configuration (if using compose)

# No persistent data storage needed
# Agent is stateless and rebuilds from Portainer server
```

## Installation

### Prerequisites

- Docker installed on the target remote host
- Port 9001 available on the target host
- Network connectivity between Portainer server and agent host
- Central Portainer instance already deployed (see Portainer README)

### Deployment

1. **Create directory structure:**

```bash
sudo docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.33.5
```

### Verification

Confirm the agent is running:

```bash
sudo docker ps -a | grep portainer_agent
```

Expected output should show the container running on port 9001.

## Configuration

### Volume Mounts Explained

| Host Path | Container Path | Purpose |
| ----------- | ---------------- | --------- |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker API access (required) |
| `/var/lib/docker/volumes` | `/var/lib/docker/volumes` | Access to Docker volumes |
| `/` | `/host` | Host filesystem access for monitoring |

### Port Configuration

| Port | Protocol | Purpose |
|------|----------|---------|
| 9001 | TCP | Agent communication with Portainer server |

**Important**: The root filesystem mount (`/:/host`) provides Portainer with visibility into the host system for comprehensive management capabilities.

## Connecting to Portainer Server

After deploying the agent on your remote host, add it to your central Portainer instance.

### Step-by-Step Connection

1. **Access Portainer WebUI:**
   - Navigate to `https://192.168.201:9443`
   - Log in with your admin credentials

2. **Add New Environment:**
   - Go to **Environments** (or **Administration** > **Environments**)
   - Click **Add environment**
   - Select **Docker Standalone**

3. **Configure Environment:**

   | Field | Value | Example |
   |-------|-------|---------|
   | **Name** | Descriptive hostname | `Target hostname` |
   | **Environment URL** | `Target host IP:9001` | `Server IP:9001` |

4. **Connect:**
   - Click **Connect** or **Add environment**
   - Wait for connection verification
   - Environment should appear in your environments list

5. **Verify Connection:**
   - The new environment should show as "Connected"
   - Click on the environment name to manage it
   - You should see containers, images, and other resources

## Firewall Configuration

Allow agent communication from your Portainer server:

```bash
# On the remote host (agent machine)
# Allow Portainer server to connect to agent
sudo ufw allow from 192.168.2.201 to any port 9001 proto tcp

# Or allow from entire local network
sudo ufw allow from 192.168.2.0/24 to any port 9001 proto tcp

# Verify rules
sudo ufw status verbose
```

## Management

### Switching Between Environments

In Portainer WebUI:

1. Click the environment dropdown (top-left)
2. Select the host you want to manage
3. All container operations now apply to that host

### Viewing Agent Status

Check agent health in Portainer:

- Go to **Environments**
- Look for green "Connected" status
- Click environment name for details

## Maintenance

### Update Agent

```bash
# Using Docker Compose
cd /docker/portainer-agent
sudo docker compose -f portainer-agent-compose.yaml pull
sudo docker compose -f portainer-agent-compose.yaml up -d

# Using Docker commands
sudo docker stop portainer_agent
sudo docker rm portainer_agent
sudo docker pull portainer/agent:2.33.5
# Then re-run the docker run command
```

### Agent Logs

View agent logs on the remote host:

```bash
# View recent logs
sudo docker logs portainer_agent

# Follow logs in real-time
sudo docker logs -f portainer_agent

# View last 100 lines
sudo docker logs --tail 100 portainer_agent
```

### Restart Agent

```bash
sudo docker restart portainer_agent
```

### Remove Agent

```bash
# Using Docker Compose
sudo docker compose -f portainer-agent-compose.yaml down

# Using Docker commands
sudo docker stop portainer_agent
sudo docker rm portainer_agent
```

Then remove from Portainer WebUI:

- Go to **Environments**
- Select the environment
- Click **Remove**

## Troubleshooting

**Agent not connecting to Portainer?**

- Verify agent is running: `sudo docker ps | grep portainer_agent`
- Check network connectivity: `ping target-host-ip`
- Verify port 9001 is open: `telnet target-host-ip 9001`
- Check firewall rules on both hosts
- Review agent logs for errors

**"Unable to connect to environment" error?**

- Verify correct IP address and port in Portainer
- Ensure agent container is running
- Check if port 9001 is accessible from Portainer server
- Verify no firewall blocking between hosts

**Agent container won't start?**

- Check if port 9001 is already in use: `sudo netstat -tulpn | grep :9001`
- Verify Docker socket is accessible
- Review container logs: `sudo docker logs portainer_agent`
- Ensure sufficient system resources

**Can see agent but can't manage containers?**

- Verify Docker socket is mounted correctly
- Check volume mounts in container configuration
- Ensure agent has proper permissions
- Review agent version compatibility with Portainer server

**Connection keeps dropping?**

- Check network stability between hosts
- Verify restart policy is set to `always`
- Review firewall rules for intermittent blocking
- Check system resources on agent host

## Security Considerations

- **Full Docker Access**: Agent has complete control over host Docker
- **Root Filesystem Access**: Agent can access entire host filesystem
- **Network Security**: Limit agent port access to trusted networks only
- **Version Pinning**: Using specific version (2.33.5) for stability
- **Communication**: Consider using VPN or private network for production
- **Firewall Rules**: Restrict port 9001 to Portainer server IP only

## Performance

- **Memory Usage**: ~30-50 MB per agent
- **CPU Usage**: Minimal (< 2%)
- **Network**: Low bandwidth, primarily API calls
- **Startup Time**: < 3 seconds
- **Overhead**: Negligible impact on Docker performance

## Advanced Configuration

### Edge Agent Mode

For hosts behind NAT or firewalls:

1. In Portainer, select **Edge Agent** instead of standard agent
2. Follow deployment instructions for reverse tunnel
3. Agent connects outbound to Portainer (no inbound ports needed)

### TLS Encryption

For encrypted agent communication:

1. Generate TLS certificates
2. Mount certificates in agent container
3. Configure Portainer to use TLS for agent connections

### Custom Agent Configuration

Set environment variables in compose file:

```yaml
environment:
  - AGENT_SECRET=your_secret_key
  - LOG_LEVEL=INFO
  - AGENT_CLUSTER_ADDR=agent-cluster-address
```

## Use Cases

- **Multi-Server Media Stack**: Manage Jellyfin, Plex across multiple hosts
- **Distributed Downloads**: Control download containers on different VMs
- **Service Segregation**: Separate production and testing environments
- **Resource Distribution**: Balance containers across multiple hosts
- **Backup Hosts**: Manage backup containers remotely

## References

- [Portainer Agent Documentation](https://docs.portainer.io/admin/environments/add/docker/agent)
- [Portainer Agent Docker Hub](https://hub.docker.com/r/portainer/agent)
- [Portainer Multi-Environment Guide](https://docs.portainer.io/admin/environments)
- [Docker Socket Security](https://docs.docker.com/engine/security/protect-access/)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
