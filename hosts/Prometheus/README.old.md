# VS Home Network - Prometheus (Pi-hole DNS Server)

## 🛠️ Hardware

RaspberryPI 4b

## 💾 raspberrypi OS Installation & Initial Setup

[Raspberrypi OS dowload](https://www.raspberrypi.com/software/)

### 1. Post-Install VM Maintenance

```bash
# Update and Clean
su -
sudo apt update && sudo apt upgrade -y
sudo apt clean && apt autoremove && apt autoclean
sudo reboot now
```

### 2. Create Directory Structure

```bash
mkdir -p /docker/composefiles
```

### 3. Network Configuration (Debian Interfaces)

needs to be filled in

---

## 🔒 Security Hardening (Firewall & SSH)

### Security Hardening

For setting up security see: [SSH & Fail2Ban Configuration](</docs/networking/SSH & Fail2Ban Configuration>)

## Configuration

### Docker Installation

For setting up docker see: [SSH & Fail2Ban Configuration](</docker/networking/README.md)

### Portainer Agent Installation

For setting up Portainer Agent see: [Portainer agent Configuration](</docker/portainer-agent/README.md)

### pi-hole Installation

For setting up pi-hole see: [pi-hole Configuration](</docker/pi-hole/README.md)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
