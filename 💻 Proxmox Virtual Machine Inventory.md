# 💻 Proxmox Virtual Machine Inventory

This table summarizes the essential configuration details for your Homelab VMs, including resource allocation, storage, and boot behavior.

| VM ID | Name | Role | Cores | RAM (MB) | Boot | Order | Delay (s) | Shutdown (s) | Key Storage/Purpose |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **999** | **Prometheus** | Pi-hole DNS / DHCP | 2 | 4096 | **Yes** | **1** | 0 | 0 | OS on NVMe (32GB) |
| **101** | Midway Station | Management / Jump Server | 2 | 4096 | **Yes** | 2 | 0 | 0 | OS on NVMe (32GB) |
| **102** | Atlantis | NAS / File Serving | 2 | 4096 | **Yes** | 3 | 60 | 180 | OS (NVMe 32GB) + **RAID 5 (3x8TB - alfheim)** + **24TB HDD (aincrad)** |
| **103** | Destiny | Download Server / VPN | 2 | 4096 | **Yes** | 4 | 0 | 180 | OS (NVMe 32GB) + 1TB HDD (theseed) |
| **104** | Orion | Game Server | 2 | 4096 | No | N/A | 0 | 0 | OS (NVMe 32GB) + 1TB 2.5" SSD (sbcglocken) |

---

## 💡 Startup Order Optimization

The **Startup Order** is critical for ensuring services like your DNS server are running before dependent VMs start.

* **Prometheus (VM 999)** must be **Order 1** as it provides DNS for all other VMs.
* **Atlantis (VM 102)** has a **60-second delay** to allow complex storage (RAID) time to initialize.

### Recommended Startup Order Logic

| Order | VM ID / Name | Dependency | Rationale |
| :---: | :--- | :--- | :--- |
| **1** | **VM999 / Prometheus** | None | **Critical:** Must be up first as the network's DNS/DHCP provider. |
| **2** | **VM101 / Midway Station** | VM999 (DNS) | Management server starts once DNS is available. |
| **3** | **VM102 / Atlantis** | VM999 (DNS) | Start the NAS, allowing 60s for RAID/volume initialization. |
| **4** | **VM103 / Destiny** | VM999 (DNS) / VM102 (Storage) | Last to start, potentially depending on the NAS (Atlantis) for download storage. |
