# VS Home Network - Proxmox VM Disk Expansion

Guide for expanding virtual machine disk size in Proxmox and resizing the filesystem inside the VM.
[Quick Command Sequence](#quick-command-sequence)

## Overview

This guide covers the complete process of expanding a VM's disk in Proxmox VE, from resizing the virtual disk in the hypervisor to expanding the filesystem inside the guest operating system. This is useful when you need more storage space in an existing VM.

## Why Expand VM Disks?

- 📈 **Growing Data**: Applications and databases need more storage
- 🎬 **Media Libraries**: Running out of space for media files
- 🐳 **Docker Volumes**: Container data filling up disk
- 📊 **Log Files**: System logs consuming space
- 🔄 **Live Expansion**: No need to recreate the VM

## Prerequisites

- Root/sudo access to both Proxmox host and VM
- VM backup recommended before making changes
- Understanding of LVM (Logical Volume Manager)
- VM can stay online during disk resize (offline for safety recommended)

## Process Overview

1. **Proxmox side**: Increase virtual disk size
2. **VM side**: Expand physical volume (PV)
3. **VM side**: Extend logical volume (LV)
4. **VM side**: Resize filesystem
5. Verify new size

## Part 1: Expand Disk in Proxmox

### Via Web Interface (Recommended)

1. **Navigate to VM**:
   - Datacenter → Node → VM → Hardware

2. **Select the disk** you want to expand (usually `scsi0`)

3. **Click "Disk Action"** → **"Resize"**

4. **Enter size to add** (in GB):
   - Example: Current disk is 32GB, add `18` to make it 50GB
   - Enter just the amount to ADD, not the total size

5. **Click "Resize disk"**

### Via Command Line

```bash
# On Proxmox host
# Increase disk size by 18GB (for example)
qm resize <VM_ID> scsi0 +18G

# Example:
qm resize 102 scsi0 +18G
```

**Note**: The `+` sign means "add this much" rather than "resize to this size"

## Part 2: Verify Disk Size in VM

### Check Current Disk Layout

After resizing in Proxmox, login to the VM:

```bash
# List all block devices
lsblk

# More detailed view
lsblk -f

# Check disk sizes
fdisk -l
```

**Example output**:

```txt
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   50G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   30G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0   30G  0 lvm  /
```

Notice: `sda` shows 50G (new size), but `sda3` and the LVM are still 30G (old size)

### Check Physical Volumes

```bash
# Display physical volumes
sudo pvdisplay

# Or shorter output
sudo pvs
```

### Check Logical Volumes

```bash
# Display logical volumes
sudo lvdisplay

# Or shorter output
sudo lvs
```

### Check Volume Groups

```bash
# Display volume groups
sudo vgdisplay

# Or shorter output
sudo vgs
```

## Part 3: Expand the Partition (If Needed)

If using a partition (most common Ubuntu setup):

### Option A: Using parted (Recommended)

```bash
# Install parted if needed
sudo apt install parted -y

# Open parted on the disk (not partition)
sudo parted /dev/sda

# Inside parted:
print                    # Show current partitions
resizepart 3             # Resize partition 3 (adjust number as needed)
# When prompted, enter new end point: 100%
quit                     # Exit parted

# Verify
lsblk
```

### Option B: Using growpart

```bash
# Install cloud-guest-utils
sudo apt install cloud-guest-utils -y

# Grow partition 3 on sda
sudo growpart /dev/sda 3

# Verify
lsblk
```

## Part 4: Expand Physical Volume

Resize the LVM physical volume to use the newly available space:

```bash
# Identify your physical volume
sudo pvs

# Resize physical volume (replace sdX# with your actual device)
sudo pvresize /dev/sda3

# Verify the change
sudo pvs
sudo pvdisplay
```

**Example**:

```bash
# If your partition is /dev/sda3
sudo pvresize /dev/sda3

# Output should show increased size
# PV Name: /dev/sda3
# PV Size: 48.00 GiB (increased from 30 GiB)
```

## Part 5: Extend Logical Volume

Extend the logical volume to use all available space:

```bash
# Check volume group and logical volume names
sudo vgs
sudo lvs

# Extend logical volume to use 100% of free space
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# Alternative: Extend by specific amount
# sudo lvextend -L +18G /dev/ubuntu-vg/ubuntu-lv

# Verify
sudo lvs
sudo lvdisplay
```

**Common LV paths**:

- Ubuntu: `/dev/ubuntu-vg/ubuntu-lv`
- Debian: `/dev/<hostname>-vg/root`
- Generic: `/dev/mapper/vg_name-lv_name`

## Part 6: Resize Filesystem

### For ext4 Filesystem (Most Common)

```bash
# Resize ext4 filesystem to use all available space
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# The filesystem can be resized while mounted (online resize)
```

**Output**:

```txt
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/ubuntu-vg/ubuntu-lv is mounted on /; on-line resizing required
old_desc_blocks = 4, new_desc_blocks = 7
The filesystem on /dev/ubuntu-vg/ubuntu-lv is now 13107200 (4k) blocks long.
```

### For xfs Filesystem

```bash
# Resize XFS filesystem (must be mounted)
sudo xfs_growfs /

# Or specify the mount point
sudo xfs_growfs /dev/ubuntu-vg/ubuntu-lv
```

### For btrfs Filesystem

```bash
# Resize btrfs filesystem
sudo btrfs filesystem resize max /
```

## Part 7: Verify Changes

### Check Disk Usage

```bash
# Check filesystem size and usage
df -h

# Detailed view
df -hT

# Check specific mount point
df -h /
```

**Expected output**:

```txt
Filesystem                         Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv   48G   12G   34G  27% /
```

### Verify Block Devices

```bash
# Final check of all devices
lsblk

# Should show expanded sizes at all levels
```

**Example final output**:

```txt
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   50G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   48G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0   48G  0 lvm  /
```

## Complete Command Reference

### Quick Command Sequence

```bash
# 1. Check current state
lsblk
df -h

# 2. Resize partition (if needed)
sudo growpart /dev/sda 3

# 3. Expand physical volume
sudo pvresize /dev/sda3

# 4. Extend logical volume
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# 5. Resize filesystem
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# 6. Verify
lsblk
df -h
```

### Automation Script

Create a script for repeated expansions:

```bash
#!/bin/bash
# expand-vm-disk.sh

echo "=== Current Disk Status ==="
lsblk
df -h

echo ""
echo "=== Expanding Physical Volume ==="
sudo pvresize /dev/sda3

echo ""
echo "=== Extending Logical Volume ==="
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

echo ""
echo "=== Resizing Filesystem ==="
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

echo ""
echo "=== New Disk Status ==="
lsblk
df -h

echo ""
echo "Disk expansion completed!"
```

Make executable:

```bash
chmod +x expand-vm-disk.sh
sudo ./expand-vm-disk.sh
```

## Different Scenarios

### Scenario 1: Simple Single Partition

If the VM has a simple partition layout (no LVM):

```bash
# 1. Resize partition
sudo growpart /dev/sda 1

# 2. Resize filesystem directly
sudo resize2fs /dev/sda1

# 3. Verify
df -h
```

### Scenario 2: Multiple Disks

If adding a completely new disk:

```bash
# 1. Create partition on new disk
sudo fdisk /dev/sdb
# Press: n, p, 1, Enter, Enter, w

# 2. Create physical volume
sudo pvcreate /dev/sdb1

# 3. Extend volume group
sudo vgextend ubuntu-vg /dev/sdb1

# 4. Extend logical volume
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# 5. Resize filesystem
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

### Scenario 3: Non-LVM Setup

For VMs without LVM:

```bash
# 1. Resize partition
sudo parted /dev/sda resizepart 1 100%

# 2. Resize filesystem
sudo resize2fs /dev/sda1
```

## Troubleshooting

**Partition not showing new size after Proxmox resize?**

- Reboot the VM
- Or rescan the SCSI bus: `echo 1 | sudo tee /sys/class/block/sda/device/rescan`

**"No space left on device" error during pvresize?**

- The partition needs to be expanded first
- Use `growpart` or `parted` to resize the partition

**lvextend fails with "insufficient free space"?**

- Check volume group has free space: `sudo vgs`
- Ensure pvresize was successful: `sudo pvs`
- Verify partition was expanded: `lsblk`

**resize2fs fails?**

- Check filesystem type: `df -T`
- For XFS use: `xfs_growfs`
- For btrfs use: `btrfs filesystem resize`
- Ensure filesystem is clean: `sudo fsck -f /dev/ubuntu-vg/ubuntu-lv` (unmount first)

**Cannot unmount filesystem?**

- For root filesystem, you can resize online with ext4
- For other filesystems, boot from recovery mode
- Or use a live CD/ISO to resize

**Disk shows new size in Proxmox but not in VM?**

- Reboot the VM
- Or rescan: `echo 1 | sudo tee /sys/class/block/sda/device/rescan`

**Wrong volume group or logical volume name?**

- Find correct names:

  ```bash
  sudo vgs  # Shows volume groups
  sudo lvs  # Shows logical volumes
  ```

- Use the names shown in the output

## Best Practices

1. **Always backup before resizing** - Take a snapshot or backup
2. **Test in non-production first** - Try on a test VM
3. **Check filesystem type** - Use correct resize command
4. **Monitor disk usage** - Set up alerts before running out of space
5. **Document your changes** - Keep notes on VM disk sizes
6. **Plan for growth** - Add extra space beyond immediate needs
7. **Consider thin provisioning** - For future flexibility
8. **Regular maintenance** - Clean up old logs and temporary files

## Disk Space Management Tips

### Check What's Using Space

```bash
# Check directory sizes
sudo du -sh /* | sort -rh | head -20

# Find large files
sudo find / -type f -size +1G -exec ls -lh {} \;

# Check Docker usage (if applicable)
sudo docker system df
sudo docker system prune -a
```

### Clean Up Space

```bash
# Clean package cache
sudo apt clean
sudo apt autoremove -y

# Clean old logs
sudo journalctl --vacuum-time=7d

# Clean Docker (if applicable)
sudo docker system prune -a --volumes

# Find and remove old kernels
dpkg -l | grep linux-image
sudo apt autoremove --purge
```

## Alternative: Add a New Disk

Instead of expanding existing disk, you can add a new disk:

**Advantages**:

- No risk to existing data
- Can be used for specific purposes
- Easier to separate data

**See**: [Proxmox VM Disk Passthrough Guide](<Proxmox VM Adding Disks to VM.md>)

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Resize_disks)
- [LVM Documentation](https://tldp.org/HOWTO/LVM-HOWTO/)
- [ext4 resize2fs Manual](https://man7.org/linux/man-pages/man8/resize2fs.8.html)
- [XFS xfs_growfs Manual](https://man7.org/linux/man-pages/man8/xfs_growfs.8.html)

## License

This project is for personal use and educational purposes.

---

*Part of the VS Home Network infrastructure project*
