# 🎬 Jellyfin Media Server Deployment Guide

**VM Host:** VM 102 (Atlantis)
**Purpose:** Self-hosted media server for streaming movies, TV shows, and anime.
**Reference:** [Jellyfin Official Documentation](https://jellyfin.org/docs/general/installation/)

---

## 1. 🐳 Container Deployment

### A. Create Data Directories

Before running the container, create the necessary persistent storage folders on the host.

```bash
# Create base jellyfin directory
sudo mkdir /docker/jellyfin

# Create config and cache subdirectories
sudo mkdir /docker/jellyfin/config
sudo mkdir /docker/jellyfin/cache
```

### B. Set Folder Permissions

Set the correct ownership (`1000:1000` is the default user ID/group ID for the Jellyfin container) to prevent permission errors.

```bash
sudo chown -R 1000:1000 /docker/jellyfin
```

### C. Create Compose File

Create the configuration file on the Atlantis VM.

```bash
nano /docker/composefiles/jellyfin-compose.yaml
```

### D. Compose YAML Content

This configuration maps your mounted data drives (`drives/aincrad` and `drives/alfheim`) directly into the container.

**Note:** Replace `uid:gid` with your target user/group IDs (e.g., `1000:1000`) if you don't use the default container user.

```yaml
# see jellyfin-compose.yaml for latest running version
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    # Optional - specify the uid and gid you would like Jellyfin to use instead of root
    user: 1000:1000 # if you use the default 
    ports:
      # Web UI (HTTP)
      - 8096:8096/tcp
      # Optional HTTPS/UDP: Add these if you configure SSL/UDP support later
      # - 8920:8920/tcp # HTTPS
      # - 7359:7359/udp # Autodiscovery
      
    volumes:
      # PERSISTENCE: Stores Jellyfin databases and configuration
      - /docker/jellyfin/config:/config
      # CACHE: Stores transcoded media and temporary files
      - /docker/jellyfin/cache:/cache
      
      # MEDIA MAPPING: Map Host Drives to Container Paths
      # Aincrad (Anime)
      - type: bind
        source: /drives/aincrad/anime-shows
        target: /anime-shows
      - type: bind
        source: /drives/aincrad/anime-movies
        target: /anime-movies
      
      # Alfheim (Main Media)
      - type: bind
        source: /drives/alfheim/tv-shows
        target: /tv-shows
      - type: bind
        source: /drives/alfheim/movies
        target: /movies
        read_only: false
        
      # Optional: Extra fonts for subtitle burn-in
      # - type: bind
      #   source: /path/to/fonts
      #   target: /usr/local/share/fonts/custom
      #   read_only: true
        
    restart: 'unless-stopped'
    environment:
      # Optional: Alternative address for autodiscovery/remote access if needed
      # - JELLYFIN_PublishedServerUrl=http://example.com
      TZ: 'Europe/Amsterdam' # Set your appropriate timezone
    extra_hosts:
      # Recommended for resolving Docker host networking issues
      - 'host.docker.internal:host-gateway'
```

### E. Launch Container

Start the Jellyfin container using the compose file.

```bash
sudo docker compose -f /docker/composefiles/jellyfin-compose.yaml up -d
```

---

## 2. ⚙️ Server Configuration (WebUI)

Access the WebUI at **`http://$atlantis-ip:8096/`** to complete the setup.

### A. Initial Setup Wizard

1. **Language:** Choose the preferred server language.
2. **Server Name:** Give the server a name.
3. **Admin Account:** Create the **Admin Account** (create other user accounts later).
4. **Add Media:** Follow the steps to add the library folders, mapping the container paths:
    * `anime-shows`
    * `anime-movies`
    * `tv-shows`
    * `movies`
5. **Metadata:**
    * Preferred Metadata Language: **English**
    * Country/Region: **United States**
6. **Remote Access:** Leave **"Allow remote connections to this server"** checked.
7. **Finalize:** Complete the wizard.

### B. Settings to Change (Dashboard)

Navigate to **Dashboard** > **Settings** (or the respective sections):

#### 1. Home Screen Settings

| Section | Value | Notes |
| :--- | :--- | :--- |
| **Home screen section 1** | **Continue Watching** | |
| **Home screen section 2** | **Next Up** | |
| **Home screen section 3** | **Recently Added Media** | |
| **Home screen section 4** | **My media** | |
| **Sections 5-10** | **None** | |

| Library Order | Position |
| :--- | :--- |
| **Anime** | 1 |
| **Anime Movies** | 2 |
| **TV-Shows** | 3 |
| **Movies** | 4 |

#### 2. Playback

| Setting | Value |
| :--- | :--- |
| **Preferred audio language** | **Japanese** |

#### 3. Subtitles

| Setting | Value |
| :--- | :--- |
| **Preferred subtitle language** | **English** |

### C. Add Plugins

1. Go to **Dashboard** > **Plugins** > **Available**.
2. Install the following plugins:
    * AniDB
    * AniList
    * AniSearch
    * Fanart
    * Kitsu
    * Playback Reporting
    * TheTVDB
3. Click on **Manage Repositories** and add custom repositories (e.g., [Awesome Jellyfin](https://github.com/awesome-jellyfin/awesome-jellyfin)).
4. Install your preferred custom plugins:
    * HoverTrailer
    * Intro Skipper
