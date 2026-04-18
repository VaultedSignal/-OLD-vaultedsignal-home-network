# VS Home Network - Jellyfin Media Server

A self-hosted media streaming server for movies, TV shows, and anime content, running on Docker.

**VM Host:** VM 102 Atlantis
**Purpose:** Self-hosted media server for streaming movies, TV shows, and anime.
**Reference:** [Jellyfin Official Documentation](https://jellyfin.org/docs/)
**File:** [`jellyfin-compose.yaml`](jellyfin-compose.yaml)

---

## Overview

Jellyfin is an open-source media server that provides streaming access to your personal media library. This deployment runs on VM 102 Atlantis and serves contect with optimized settings for anime and standard media.

## Architecture

The server streams media from two primary storage locations:

- **Aincrad Drive**: Dedicated anime content (shows and movies)
- **Alfheim Drive**: Standard media (TV shows and movies)

All media is mounted directly into the container with proper permissions and persistent configuration storage.

## Technology Stack

### Core Infrastructure

- **Container Platform**: Docker
- **Media Server**: Jellyfin (Official Docker Image)
- **VM Host**: Atlantis (VM 102)
- **Storage**: Network-mounted drives (Aincrad, Alfheim)

## Features

- 🎬 Stream movies and TV shows
- 📺 Dedicated anime library support
- 🌐 Web-based interface accessible on local network
- 🔌 Plugin ecosystem for enhanced functionality
- 📱 Multi-platform client support
- 🎨 Custom metadata from multiple sources (AniDB, AniList, TheTVDB)

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

## Setup & Configuration

### Prerequisites

- Docker and Docker Compose installed on Atlantis VM
- Drives mounted at `/drives/aincrad` and `/drives/alfheim`
- Sufficient storage for configuration and cache

### Installation

1. Create the compose file

```bash
sudo nano /docker/composefiles/jellyfin-compose.yaml
```

2. Copy the [jellyfin-compose.yaml](jellyfin-compose.yaml)
3. Start the stack:

```bash
sudo docker compose -f /docker/composefiles/jellyfin-compose.yaml up -d
```

4. Access the services via `http://192.168.2.202:PORT`

The web interface is accessible via [`http://192.168.2.202:8096`](http://192.168.2.203:8096)

## Configuration Notes

### Media Library Structure

| Container Path | Host Path | Content Type |
| ---------------- | ----------- | -------------- |
| `/anime-shows` | `/drives/aincrad/anime-shows` | Anime TV Series |
| `/anime-movies` | `/drives/aincrad/anime-movies` | Anime Films |
| `/tv-shows` | `/drives/alfheim/tv-shows` | Standard TV Shows |
| `/movies` | `/drives/alfheim/movies` | Standard Movies |

## Initial Setup

Access the web UI at `http://192.168.2.202:8096` and complete the setup wizard:

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
| --------- | --------- |
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

## Security Notes

- Container runs as non-root user (UID:GID 1000:1000)
- Media volumes are mounted with read-write access
- Remote access is enabled by default (configure reverse proxy for HTTPS in production)

## Maintenance

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

### View Container Logs

```bash
docker logs jellyfin
docker logs -f jellyfin  # Follow mode
```

### Restart Container

```bash
docker restart jellyfin
```

## Troubleshooting

**Cannot access web UI?**

- Verify container is running: `docker ps | grep jellyfin`
- Check if port 8096 is accessible: `curl http://192.168.2.202:8096`
- Review logs for errors: `docker logs jellyfin`

**Media not showing up?**

- Verify drive mounts are accessible
- Check file permissions (should be readable by UID 1000)
- Trigger library scan in Dashboard > Libraries

**Transcoding issues?**

- Check available disk space in `/docker/jellyfin/cache`
- Review transcoding logs in Dashboard > Logs
- Ensure proper hardware acceleration if configured

## References

[Jellyfin Official Documentation](https://jellyfin.org/docs/)
[Jellyfin Official Documentation](https://jellyfin.org/docs/)
[Jellyfin Docker Hub](https://hub.docker.com/r/jellyfin/jellyfin)
[Awesome Jellyfin Plugins](https://github.com/awesome-jellyfin/awesome-jellyfin)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
