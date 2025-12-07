# 🐳 Docker Engine Installation

**Purpose:** Install the Docker Engine, CLI, and Containerd using the official Docker repository to ensure the latest, stable version on any Debian-based distribution.

---

## 1. Prerequisites and Dependencies

Install the required utility packages needed to manage repositories over HTTPS.

```bash
# 1. Update package index
sudo apt update

# 2. Install packages for repository management
sudo apt install ca-certificates curl gnupg lsb-release -y
```

---

## 2. Add Docker's Official GPG Key

Docker signs its packages. You must add the GPG key to verify package authenticity and trust the source.

```bash
# 1. Create directory for keyring
sudo mkdir -p /etc/apt/keyrings

# 2. Download the GPG key, de-armor it, and save it to the keyrings directory
# The gpg command may require elevated privileges
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

---

## 3. Set up the Stable Repository

Add the Docker stable repository to your system's package list. The command uses `$(lsb_release -cs)` to automatically determine your distribution's codename (e.g., `jammy`, `bullseye`).

```bash
# Add the Docker stable repository to Apt sources list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again with the new repository
sudo apt update
```

---

## 4. Install Docker Engine

Install the core packages: the Docker Engine (`docker-ce`), the Command Line Interface (`docker-ce-cli`), and the container runtime (`containerd.io`).

```bash
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

---

## 5. Post-Installation Setup (Non-Root User)

To manage Docker containers without using `sudo` every time, you must add your user to the `docker` group.

```bash
# 1. Add your current user ($USER) to the docker group
sudo usermod -aG docker $USER

# 2. Activate the change: You must log out and log back in, 
#    OR run 'newgrp docker' to apply the group change immediately 
#    to your current terminal session.
newgrp docker
```

---

## 6. Verification

Run the `hello-world` container to ensure Docker is installed correctly and is accessible by your non-root user.

```bash
# This command pulls and runs a test container
docker run hello-world
```

If successful, you will see a message confirming the installation works.
