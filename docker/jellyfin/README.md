# Jellyfin Media Server

A self-hosted media streaming server for movies, TV shows, and anime content, running on Docker.

## Overview

Jellyfin is an open-source media server that provides streaming access to your personal media library. This deployment runs on VM 102 (Atlantis) and serves content from multiple network drives with optimized settings for anime and standard media.

## Technology Stack

- **Container Platform**: Docker
- **Media Server**: Jellyfin (Official Docker Image)
- **VM Host**: Atlantis (VM 102)
- **Storage**: Network-mounted drives (Aincrad, Alfheim)

## Architecture

The server streams media from two primary storage locations:

- **Aincrad Drive**: Dedicated anime content (shows and movies)
- **Alfheim Drive**: Standard media (TV shows and movies)

All media is mounted directly into the container with proper permissions and persistent configuration storage.

## Features

- 🎬 Stream movies and TV shows
- 📺 Dedicated anime library support
- 🌐 Web-based interface accessible on local network
- 🔌 Plugin ecosystem for enhanced functionality
- 📱 Multi-platform client support
- 🎨 Custom metadata from multiple sources (AniDB, AniList, TheTVDB)

## Installation

### Prerequisites

- Docker and Docker Compose installed on Atlantis VM
- Drives mounted at `/drives/aincrad` and `/drives/alfheim`
- Sufficient storage for configuration and cache

### Directory Setup

Create the required directories with proper permissions:

```bash
# Create base directory structure
sudo mkdir -p /docker/jellyfin/{config,cache}

# Set correct ownership (UID:GID 1000:1000)
sudo chown -R 1000:1000 /docker/jellyfin
```

### Deployment

1. **Create the compose file:**

```bash
nano /docker/composefiles/jellyfin-compose.yaml
```

2.**Add the configuration** (see docker-compose.yml in repository)

3.**Start the container:**

```bash
sudo docker compose -f /docker/composefiles/jellyfin-compose.yaml up -d
```

## Configuration

### Docker Compose Configuration

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000
    ports:
      - 8096:8096/tcp    # Web UI (HTTP)
      # - 8920:8920/tcp  # HTTPS (optional)
      # - 7359:7359/udp  # Autodiscovery (optional)
    volumes:
      - /docker/jellyfin/config:/config
      - /docker/jellyfin/cache:/cache
      - /drives/aincrad/anime-shows:/anime-shows
      - /drives/aincrad/anime-movies:/anime-movies
      - /drives/alfheim/tv-shows:/tv-shows
      - /drives/alfheim/movies:/movies
    environment:
      - TZ=Europe/Amsterdam
    restart: unless-stopped
    extra_hosts:
      - 'host.docker.internal:host-gateway'
```

### Media Library Structure

| Container Path | Host Path | Content Type |
|----------------|-----------|--------------|
| `/anime-shows` | `/drives/aincrad/anime-shows` | Anime TV Series |
| `/anime-movies` | `/drives/aincrad/anime-movies` | Anime Films |
| `/tv-shows` | `/drives/alfheim/tv-shows` | Standard TV Shows |
| `/movies` | `/drives/alfheim/movies` | Standard Movies |

## Initial Setup

Access the web UI at `http://atlantis-ip:8096` and complete the setup wizard:

### 1. Basic Configuration

- Select server language
- Set server name
- Create admin account

### 2. Media Libraries

Add libraries for each media type, mapping to container paths:

- `/anime-shows`
- `/anime-movies`
- `/tv-shows`
- `/movies`

### 3. Metadata Settings

- **Preferred Language**: English
- **Country/Region**: United States
- **Remote Access**: Enabled

### 4. Home Screen Layout

Configure the dashboard sections in order:

| Section | Content |
|---------|---------|
| Section 1 | Continue Watching |
| Section 2 | Next Up |
| Section 3 | Recently Added Media |
| Section 4 | My Media |
| Sections 5-10 | None |

**Library Display Order:**

1. Anime
2. Anime Movies
3. TV-Shows
4. Movies

### 5. Playback & Subtitle Settings

**Playback:**

- Preferred audio language: **Japanese** (for anime content)

**Subtitles:**

- Preferred subtitle language: **English**

## Plugins

### Core Metadata Plugins

Install these for enhanced metadata retrieval:

- **AniDB** - Anime metadata
- **AniList** - Anime tracking integration
- **AniSearch** - Additional anime data
- **Fanart** - High-quality artwork
- **Kitsu** - Anime metadata alternative
- **TheTVDB** - TV show metadata
- **Playback Reporting** - Usage statistics

### Custom Plugins

Add custom plugin repositories via **Dashboard > Plugins > Manage Repositories**:

- [Awesome Jellyfin](https://github.com/awesome-jellyfin/awesome-jellyfin)

**Recommended Custom Plugins:**

- **HoverTrailer** - Trailer previews on hover
- **Intro Skipper** - Auto-skip episode intros

## Access & Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8096 | TCP | Web UI (HTTP) |
| 8920 | TCP | HTTPS (Optional) |
| 7359 | UDP | Auto-discovery (Optional) |

**Web Interface**: `http://atlantis-ip:8096`

## Maintenance

### View Container Logs

```bash
docker logs jellyfin
docker logs -f jellyfin  # Follow mode
```

### Restart Container

```bash
docker restart jellyfin
```

### Update to Latest Version

```bash
cd /docker/composefiles
docker compose -f jellyfin-compose.yaml pull
docker compose -f jellyfin-compose.yaml up -d
```

### Backup Configuration

```bash
# Backup config directory
sudo tar -czf jellyfin-config-backup-$(date +%Y%m%d).tar.gz /docker/jellyfin/config
```

## Storage Locations

```txt
/docker/jellyfin/
  ├── config/          # Jellyfin configuration and database
  └── cache/           # Transcoded media and temporary files

/drives/
  ├── aincrad/
  │   ├── anime-shows/
  │   └── anime-movies/
  └── alfheim/
      ├── tv-shows/
      └── movies/
```

## Troubleshooting

**Cannot access web UI?**

- Verify container is running: `docker ps | grep jellyfin`
- Check if port 8096 is accessible: `curl http://localhost:8096`
- Review logs for errors: `docker logs jellyfin`

**Media not showing up?**

- Verify drive mounts are accessible
- Check file permissions (should be readable by UID 1000)
- Trigger library scan in Dashboard > Libraries

**Transcoding issues?**

- Check available disk space in `/docker/jellyfin/cache`
- Review transcoding logs in Dashboard > Logs
- Ensure proper hardware acceleration if configured

## Security Notes

- Container runs as non-root user (UID:GID 1000:1000)
- Media volumes are mounted with read-write access
- Remote access is enabled by default (configure reverse proxy for HTTPS in production)

## References

- [Jellyfin Official Documentation](https://jellyfin.org/docs/)
- [Jellyfin Docker Hub](https://hub.docker.com/r/jellyfin/jellyfin)
- [Awesome Jellyfin Plugins](https://github.com/awesome-jellyfin/awesome-jellyfin)

---

*Part of the SGC Home Network infrastructure project*
