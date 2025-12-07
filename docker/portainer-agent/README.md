# 🤖 Portainer Agent Installation

**Purpose:** Deploy the Portainer Agent on a remote Docker host for central management via the main Portainer server (Midway Station).
**VMs:** Target is any remote host (e.g., Atlantis or Orion).

---

## 1. On the Remote Docker Host (Target VM)

### A. Run the Agent Container

On the **target machine's CLI** execute the following command as `sudo`.

* **Port Mapping:** Exposes port **`9001`** for communication.
* **Volumes:** Maps essential Docker directories and the root filesystem (`/:/host`) for full management capabilities.

```bash
#this a docker run command see .yaml file for current in use compose version.
sudo docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.33.5
```

### B. Verification

Check that the agent container is running:

```bash
sudo docker ps -a | grep portainer_agent
```

---

## 2. On the Central Portainer WebUI (Midway Station)

Once the agent is running on the remote host, connect it to your central Portainer instance (Midway Station) using your browser at **`https://[Midway Station IP]:9443/`**.

### A. Add Environment

1.  Navigate to **Administration** > **Environment-related** > **Enviorments**.
2.  Click **Add Environment**.
3.  Choose **Docker Standalone**

### B. Configuration

Fill in the details for the remote environment:

| Field | Value | Notes |
| :--- | :--- | :--- |
| **Name** | `$hostname-target-machine` | |
| **Environment address** | `$target-machine-ip:9001` | Use the **IP address** of the target machine, followed by port `9001`. |

Click **Connect**.

The target VM should now appear as a new environment on your Portainer home screen, ready for centralized management.
