# ⚙️ Proxmox VM: Adding Direct Disks (Pass-through)

**Author:** [VaultedSignal]
**Date:** [06-12-2025]
**Purpose:** Procedure for adding an entire physical drive to a Proxmox VM using the `qm set` command and disk ID (recommended for stability).

---

## 🚀 Overview and Requirements

This method requires **stopping the target VM** and uses the disk's **World Wide Name (WWN)** or similar stable ID (found in `/dev/disk/by-id/`) to ensure the disk is always presented correctly, even if the `/dev/sdX` designation changes.

---

## 🛠️ Step-by-Step Procedure

Follow these steps on the **Proxmox Host** to safely attach the disk.

### 1. Stop the Virtual Machine

Before making hardware changes, ensure the VM is stopped.
```bash
sudo qm stop $vm-id
```

### 2. Identify the Target Drive

Identify the device name (e.g., `/dev/sdb`) of the drive you wish to pass through.
```bash
lsblk
```

### 3. Ensure the Drive is Unmounted

If the drive was previously mounted or has partitions, you must **unmount** them to prevent data corruption or conflicts.
```bash
sudo umount /dev/sdX* # Unmounts all partitions as well (e.g., /dev/sdb*)
```

### 4. Get the Stable Disk ID (WWN)

This is the **most crucial step**. Find the long, stable identifier for the drive. Look for entries starting with `wwn-`, `ata-`, or `scsi-` that correspond to your drive.

```bash
ls -l /dev/disk/by-id/
```

> **Note:** Write down the **full disk ID** (e.g., `wwn-0x0000a000e0aaa000`).

### 5. Attach the Disk to the VM

Use the `qm set` command, specifying the **VM ID**, the **SCSI slot** (e.g., `-scsi1`), and the **full path to the stable ID**.

```bash
sudo qm set $vm-id -scsi1 /dev/disk/by-id/$disk-id
```

### 6. Start the Virtual Machine

Once the disk is attached, restart the VM. The new drive will be available inside the guest operating system (OS).
```bash
sudo qm start $vm-id
```

---

## 💡 Important Settings & Gotchas

| Setting | Value/Action | Description |
| :--- | :--- | :--- |
| **SCSI Slot** | `-scsi1`, `-scsi2`, etc. | Choose an **unused** SCSI slot. Check the VM's Hardware tab. |
| **Caching** | `writeback` or `none` | **Recommendation:** Set to `none` if passing an entire physical disk for maximum data integrity. |
| **VM OS** | **Linux:** `fdisk` or `parted` | You will need to partition and format the disk **inside the VM**. |
