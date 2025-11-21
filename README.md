# Home-network
My evolving home network




Host: Proxmox

VMs:

VM 1 – VPN + Download stack (Gluetun + qBittorrent + Arrstack)

Dedicated CPU/RAM

All traffic forced through VPN

Kill-switch firewall rules

VM 2 – Media server / File storage (Jellyfin + Kavita + Audiobookshelf)

Direct disk access for media library

CPU/RAM scaled for simultaneous streams and indexing

VM 3 – Game server

GPU passthrough if required

Dedicated CPU/RAM

LXCs (lightweight, low-resource services):

LXC 1 – Portainer (container management)

LXC 2 – PiHole (network-wide adblock/DNS)

LXC 3 – Homarr (dashboard)

LXC 4 – Jellyseer (Jellyfin monitoring)

Notes on layout:

Keep VPN + download apps together to enforce kill-switch behavior.

Media server in its own VM prevents heavy I/O from affecting other services.

Lightweight services in LXCs save overhead and simplify maintenance.

Ensure clear network segmentation: e.g., downloads VM isolated, PiHole/LXCs accessible to LAN, media server accessible to LAN and VPN clients if needed.
