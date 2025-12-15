# SGC Home Network - Media Automation Stack

A Docker-based media automation infrastructure running behind a VPN for secure torrent management and content acquisition.

## Overview

This project implements a complete media server stack using Docker Compose, with all traffic routed through a VPN (Gluetun) for privacy and security. The setup includes automatic torrent management, indexer aggregation, and separate instances for standard and anime content.

## Architecture

All services run in Docker containers with traffic routed through **Gluetun**, ensuring all download and indexer traffic goes through a NordVPN connection. This provides:

- **Privacy Protection**: All torrent traffic is encrypted and routed through VPN
- **Kill Switch**: If VPN connection drops, containers cannot access the internet
- **Network Isolation**: Media acquisition services are isolated from the host network

## Technology Stack

### Core Infrastructure

- **VPN Gateway**: Gluetun (NordVPN via OpenVPN)
- **Containerization**: Docker & Docker Compose
- **Operating System**: Linux (Ubuntu/Debian)

### Media Automation Services

- **qBittorrent**: Torrent client with web UI
- **Prowlarr**: Indexer aggregator and manager
- **Sonarr**: TV show automation (2 instances: standard + anime)
- **Radarr**: Movie automation (2 instances: standard + anime)
- **Huntarr**: Additional media management
- **Cleanuparr**: Automated cleanup utility

## Services & Ports

| Service | Port | Purpose |
|---------|------|---------|
| qBittorrent | 8080 | Torrent client web UI |
| Prowlarr | 9696 | Indexer management |
| Sonarr | 8989 | TV show automation |
| Sonarr-Anime | 8990 | Anime show automation |
| Radarr | 7878 | Movie automation |
| Radarr-Anime | 7879 | Anime movie automation |
| Huntarr | 8686 | Media management |
| Cleanuparr | 5050 | Cleanup automation |

## Storage Structure

```txt
/docker/              # Docker container configurations
  ├── gluetun/
  ├── qbittorrent/
  ├── prowlarr/
  ├── sonarr/
  ├── sonarr-anime/
  ├── radarr/
  ├── radarr-anime/
  ├── huntarr/
  └── cleanuparr/

/drives/
  ├── theseed/
  │   ├── downloads/
  │   │   ├── incomplete/  # Active downloads
  │   │   └── complete/    # Finished downloads
  │   └── torrents/        # Auto-add .torrent files
  ├── alfheim/
  │   ├── tv-shows/        # Standard TV shows
  │   └── movies/          # Standard movies
  └── aincrad/
      ├── anime-shows/     # Anime series
      └── anime-movies/    # Anime films
```

## Setup & Configuration

### Prerequisites

1. Docker and Docker Compose installed
2. NordVPN account with OpenVPN credentials
3. Proper directory structure created with correct permissions

### Environment Variables

Create a `.env` file in the same directory as `docker-compose.yml`:

```env
nordvpnuser=your_nordvpn_username
nordvpnpasswd=your_nordvpn_password
lanip=192.168.1.0  # Replace with your local network subnet
```

### Installation

1. Clone this repository
2. Create the required directory structure
3. Set up your `.env` file with credentials
4. Start the stack:

```bash
docker-compose up -d
```

5. Access the services via `http://your-server-ip:PORT`

## Configuration Notes

### Multiple Instances

The setup runs two instances each of Sonarr and Radarr to separate standard and anime content:

- Each instance uses a **different port** (configured via `PORT` environment variable)
- Each instance has **separate config directories**
- Configure the hostname in each instance: `Settings > General > Advanced > Hostname`

### VPN Configuration

- **Provider**: NordVPN (TCP protocol for P2P)
- **Server Location**: Poland (configurable via `SERVER_COUNTRIES`)
- **Local Network Access**: Configured via `FIREWALL_OUTBOUND_SUBNETS` to allow communication with local services

### Network Mode

All services use `network_mode: "service:gluetun"`, which means:

- They share Gluetun's network stack
- All traffic is routed through the VPN
- Services communicate with each other through the shared network
- No direct host network access

## Security Features

- ✅ All download traffic encrypted through VPN
- ✅ Kill switch protection (containers stop if VPN fails)
- ✅ Network isolation from host system
- ✅ Local subnet access for integration with other services

## Maintenance

### View Logs

```bash
docker-compose logs -f [service_name]
```

### Restart Services

```bash
docker-compose restart [service_name]
```

### Update Containers

```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

**Services not accessible?**

- Check if Gluetun is healthy: `docker-compose ps`
- Verify VPN connection: `docker-compose logs gluetun`

**Can't connect to indexers?**

- Ensure Prowlarr is configured and connected to VPN
- Check firewall rules in Gluetun logs

**Multiple instances conflicting?**

- Verify each instance uses unique ports
- Check that hostname is set in General > Advanced settings

## License

This project is for personal use and educational purposes.

---

*Part of the SGC Home Network infrastructure project*
