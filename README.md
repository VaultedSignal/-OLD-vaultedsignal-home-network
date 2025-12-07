# 🚀 VaultedSignal Home Lab Infrastructure

## 🌟 Project Overview

This repository documents the complete configuration, deployment steps, and inventory for the **VaultedSignal Home Lab** infrastructure. The goal is to achieve **Infrastructure as Code (IaC)** principles, making the entire environment highly reproducible, secure, and easy to maintain.

The lab is built on **Proxmox VE** and primarily utilizes **Debian/Ubuntu Server** VMs configured for various network services and dedicated applications.

---

## 🎯 Key Design Principles

* **Security First:** All critical services (like SSH) are restricted using UFW and Fail2Ban, accessible only via a hardened Jump Server (`midway-station`).
* **Centralized DNS:** All network traffic is managed and filtered by a dedicated Pi-hole DNS server (`prometheus`).
* **Repeatability:** All configurations (VM specs, networking, storage, Docker) are stored here, allowing for the environment to be rapidly redeployed or scaled.

---

## 💻 Infrastructure Inventory

The following virtual machines constitute the core lab environment:

| VM ID | Hostname | OS | Purpose | Startup Order | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **999** | **prometheus** | Debian | Primary DNS / Pi-hole Server | **1 (CRITICAL)** | Active |
| **101** | **midway-station** | Ubuntu | Management / Jump Server / Portainer Server | 2 | Active |
| **102** | **atlantis** | Ubuntu | Network Attached Storage (NAS) / File Server | 2 | Active |
| **103** | **destiny** | Ubuntu | Download Server / VPN Client | 3 | Active |
| **104** | **orion** | Ubuntu | Dedicated Game Server Host | Manual | Active |

---

## 🧭 Getting Started

To fully understand and replicate this infrastructure, start with the centralized documentation in the `/docs` folder.

### 📚 Core Documentation

| File | Description |
| :--- | :--- |
| `docs/01-inventory.md` | **Master Inventory.** Central source of truth for all IP addresses, storage UUIDs, mount points, and server roles. **(Start Here)** |
| `docs/03-initial-setup.md` | General checklist for preparing a new Proxmox VM before customization. |
| `/vms/` | Detailed, step-by-step installation and hardening guides for each individual VM. |

### 🐳 Application Guides

| Path | Description |
| :--- | :--- |
| `docker/pi-hole/` | Docker Compose file and setup notes for the Pi-hole deployment. |
| `docker/portainer/` | Docker Compose file for the central Portainer management interface. |
| `docker/portainer-agent/` | Instructions and command for deploying the Portainer Agent on remote hosts. |
| `scripts/` | Common shell scripts used for initial VM preparation (updates, directory creation). |

---

## 🛠️ Deployment Workflow (New VM)

1. **VM Creation:** Follow the Proxmox specifications found in the respective VM's folder (`/vms/vm-XXX-name/README.md`).
2. **OS Installation:** Install the base OS (Ubuntu/Debian).
3. **Basic Setup:** Run common cleanup and directory creation scripts from `/scripts/`.
4. **Network Config:** Apply the static IP settings (Netplan/interfaces) specified in the VM's guide.
5. **Security Hardening:** Apply **UFW** and **Fail2Ban** rules (allowing SSH only from `midway-station`).
6. **Storage/Application:** Configure storage mounts (`/etc/fstab`) and deploy Docker applications (using YAML files from `/docker`).

---

## 🤝 Contribution

This repository is primarily for personal use, but feel free to open an issue if you have suggestions or spot an error.
