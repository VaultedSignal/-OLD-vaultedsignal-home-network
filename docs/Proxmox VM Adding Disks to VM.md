# Proxmox VM Disk Passthrough

Guide for attaching physical drives directly to Proxmox virtual machines using stable disk identifiers.

## Overview

This guide covers the process of passing through entire physical disks to Proxmox VMs. Unlike virtual disks, this method provides direct access to physical storage devices, making it ideal for large storage arrays, NAS setups, or when maximum I/O performance is required.

## Why Use Disk Passthrough?

- 🚀 **Better Performance**: Direct disk access without virtualization overhead
- 💾 **Large Storage**: Ideal for media libraries and backup storage
- 🔄 **Data Portability**: Disks can be moved between hosts if needed
- ⚡ **Native Speed**: Full disk bandwidth and IOPS
- 🎯 **Dedicated Storage**: Isolate storage for specific VMs

## Technology Stack

- **Hypervisor**: Proxmox VE
- **Disk Interface**: SCSI passthrough
- **Identification Method**: WWN/Stable disk IDs
- **Supported Disks**: SATA, SAS, NVMe

## Important Considerations

### Advantages

- Direct hardware access provides maximum performance
- No storage overhead from virtual disk layers
- Easy to identify and manage specific physical disks
- Data remains portable between systems

### Disadvantages

- Cannot use Proxmox snapshot features for passed-through disks
- No live migration support for VMs with passthrough disks
- Disk must be unmounted on host before passthrough
- Requires VM shutdown for attachment

## Prerequisites

- Root access to Proxmox host
- Physical disk available and not in use
- VM must be stopped before disk attachment
- Understanding of disk identification methods in Linux

## Disk Passthrough Process

### Step 1: Stop the Target VM

**Critical**: Always stop the VM before making hardware changes:

```bash
# Stop the VM (replace with actual VM ID)
qm stop 100

# Verify VM is stopped
qm status 100
```

### Step 2: Identify Available Disks

List all block devices on the Proxmox host:

```bash
# View all disks and partitions
lsblk

# Detailed disk information
fdisk -l

# Show disk sizes and usage
df -h
```

**Example output**:

```txt
NAME   SIZE TYPE MOUNTPOINT
sda    500G disk
├─sda1 499G part /
└─sda2   1G part [SWAP]
sdb      2T disk          <- Target disk for passthrough
sdc      4T disk
```

### Step 3: Unmount the Target Disk

If the disk has mounted partitions, unmount them first:

```bash
# Check if disk is mounted
mount | grep sdb

# Unmount all partitions on the disk
umount /dev/sdb*

# Verify unmount was successful
mount | grep sdb
```

**Important**: Unmounting is crucial to prevent:

- Data corruption
- File system conflicts
- Kernel panic in the VM

### Step 4: Find Stable Disk Identifier

Use stable identifiers instead of `/dev/sdX` names (which can change):

```bash
# List all stable disk identifiers
ls -l /dev/disk/by-id/

# Filter for specific disk (if you know the serial)
ls -l /dev/disk/by-id/ | grep -i "serial_number"
```

**Common identifier types**:

- `wwn-0x...` - World Wide Name (most stable)
- `ata-BRAND_MODEL_SERIAL` - ATA device identifier
- `scsi-SATA_BRAND_MODEL_SERIAL` - SCSI device identifier
- `nvme-eui...` - NVMe identifier

**Example output**:

```txt
lrwxrwxrwx 1 root root  9 Dec  6 10:00 ata-WDC_WD20EZRZ-00Z5HB0_WD-12345 -> ../../sdb
lrwxrwxrwx 1 root root  9 Dec  6 10:00 wwn-0x5000cca264eb1234 -> ../../sdb
```

**Choose the identifier**: Use the full `wwn-` or `ata-` identifier.

### Step 5: Attach Disk to VM

Use the `qm set` command to attach the disk:

```bash
# Attach disk to VM using stable identifier
# Format: qm set <VM_ID> -scsi<N> /dev/disk/by-id/<DISK_ID>

# Example with WWN identifier
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234

# Example with ATA identifier
qm set 102 -scsi2 /dev/disk/by-id/ata-WDC_WD20EZRZ-00Z5HB0_WD-12345
```

**SCSI slot numbers**:

- `-scsi0` - Usually reserved for VM boot disk
- `-scsi1` to `-scsi30` - Available for additional disks
- Check VM's Hardware tab in Proxmox GUI for used slots

### Step 6: Configure Disk Settings (Optional)

Adjust disk settings for optimal performance:

```bash
# Set cache mode to 'none' for data integrity (recommended)
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234,cache=none

# Set cache mode to 'writeback' for performance (if you have UPS backup)
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234,cache=writeback

# Enable discard/TRIM for SSDs
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234,discard=on,ssd=1
```

### Step 7: Start the VM

After attaching the disk, start the VM:

```bash
# Start the VM
qm start 100

# Monitor boot process
qm terminal 100
```

## Configuring the Disk Inside the VM

After the VM boots, the new disk will be available but unformatted.

### On Linux VMs

1. **Identify the new disk**:

```bash
# List all disks
lsblk

# Check disk details
fdisk -l
```

2.**Create partition (optional)**:

```bash
# For single large partition
fdisk /dev/sdb

# Or use parted for GPT
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary ext4 0% 100%
```

3.**Format the disk**:

```bash
# For ext4 filesystem
mkfs.ext4 /dev/sdb1

# For XFS filesystem (recommended for large disks)
mkfs.xfs /dev/sdb1

# For entire disk without partition
mkfs.ext4 /dev/sdb
```

4.**Mount the disk**:

```bash
# Create mount point
mkdir -p /mnt/storage

# Mount the disk
mount /dev/sdb1 /mnt/storage

# Add to /etc/fstab for persistent mount
echo "/dev/sdb1 /mnt/storage ext4 defaults 0 2" >> /etc/fstab
```

5.**Verify mount**:

```bash
df -h | grep storage
```

### On Windows VMs

1. Open **Disk Management** (diskmgmt.msc)
2. The new disk will appear as "Unallocated"
3. Right-click > **Initialize Disk** > Choose GPT or MBR
4. Right-click unallocated space > **New Simple Volume**
5. Follow wizard to format and assign drive letter

## Configuration Options

### Cache Modes

| Mode | Use Case | Performance | Safety |
|------|----------|-------------|--------|
| `none` | Production, databases | Good | Best |
| `writethrough` | Balanced workloads | Medium | Good |
| `writeback` | Max performance with UPS | Best | Requires UPS |
| `directsync` | Maximum safety | Lowest | Maximum |

**Recommendation**: Use `cache=none` for data integrity unless you have UPS backup.

### SSD Optimization

For SSDs, enable TRIM/discard:

```bash
qm set 100 -scsi1 /dev/disk/by-id/nvme-Samsung_SSD_123,discard=on,ssd=1
```

### I/O Thread

Enable I/O threads for better performance:

```bash
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x123,iothread=1
```

## Verification

### On Proxmox Host

```bash
# View VM configuration
qm config 100

# Check disk attachment
qm config 100 | grep scsi1

# Monitor VM disk I/O
qm monitor 100
```

### Inside the VM

```bash
# List block devices
lsblk

# Check disk performance
hdparm -tT /dev/sdb

# Verify mount points
df -h

# Check I/O statistics
iostat -x 1
```

## Management

### Detach Disk from VM

To remove a passed-through disk:

```bash
# Stop the VM
qm stop 100

# Remove the disk
qm set 100 --delete scsi1

# Verify removal
qm config 100 | grep scsi1
```

### Move Disk to Different VM

```bash
# Stop both VMs
qm stop 100
qm stop 200

# Detach from first VM
qm set 100 --delete scsi1

# Attach to second VM
qm set 200 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234

# Start the new VM
qm start 200
```

### Replace Failed Disk

```bash
# Stop VM
qm stop 100

# Physically replace disk in server

# Update configuration with new disk ID
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb5678

# Start VM
qm start 100
```

## Troubleshooting

**Disk not showing in VM?**

- Verify VM is completely stopped before attachment
- Check SCSI controller type in VM settings (VirtIO SCSI recommended)
- Ensure disk identifier is correct
- Check Proxmox logs: `journalctl -xe`

**"Device is busy" error?**

- Unmount all partitions: `umount /dev/sdX*`
- Check for processes using disk: `lsof | grep sdX`
- Kill processes if safe: `fuser -km /dev/sdX`

**Wrong disk attached?**

- Always use `/dev/disk/by-id/` paths
- Verify identifier matches expected disk
- Use `lsblk -o NAME,SIZE,SERIAL,MODEL` to confirm

**Performance issues?**

- Set cache mode to `none` or `writeback`
- Enable I/O threads
- Check for SCSI controller bottlenecks
- Monitor with `iostat` inside VM

**Disk identifier changed after reboot?**

- This shouldn't happen with WWN/stable IDs
- Verify you used `/dev/disk/by-id/` not `/dev/sdX`
- Check if disk firmware updated
- Re-identify and update VM configuration

**Cannot unmount disk?**

- Check mounted filesystems: `mount | grep sdX`
- Find processes: `lsof /dev/sdX`
- Force unmount: `umount -f /dev/sdX`
- Lazy unmount: `umount -l /dev/sdX`

## Best Practices

1. **Always use stable identifiers** (`/dev/disk/by-id/`) never `/dev/sdX`
2. **Stop VMs before disk changes** to prevent data corruption
3. **Document disk assignments** in VM notes for future reference
4. **Use cache=none** for data integrity unless you have UPS
5. **Enable TRIM for SSDs** to maintain performance
6. **Monitor disk health** with SMART tools on Proxmox host
7. **Test disaster recovery** procedures before actual need
8. **Keep backups** - passthrough disks cannot use Proxmox snapshots

## Multiple Disk Passthrough

To attach multiple disks to one VM:

```bash
# Stop VM
qm stop 100

# Attach multiple disks to different SCSI slots
qm set 100 -scsi1 /dev/disk/by-id/wwn-0x5000cca264eb1234
qm set 100 -scsi2 /dev/disk/by-id/wwn-0x5000cca264eb5678
qm set 100 -scsi3 /dev/disk/by-id/wwn-0x5000cca264eb9abc

# Start VM
qm start 100
```

## Security Considerations

- Passed-through disks have no isolation between host and VM
- VM has direct access to raw disk hardware
- Data on disk is not encrypted by Proxmox
- Consider disk-level encryption (LUKS) inside VM if needed
- Physical security is crucial for data protection

## Performance Notes

- **Passthrough vs Virtual Disk**: Passthrough typically provides 5-15% better performance
- **SCSI vs IDE**: Always use VirtIO SCSI for best performance
- **I/O Threads**: Enable for high-IOPS workloads
- **Cache Modes**: Balance between safety and performance based on workload

## Limitations

- ❌ No Proxmox snapshots for passthrough disks
- ❌ No live migration with passthrough disks
- ❌ Disk must be dedicated to one VM at a time
- ❌ Cannot thin-provision passthrough disks
- ✅ Can use VM-level snapshots (excluding passthrough disk)
- ✅ Can backup passthrough disk data from within VM

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Proxmox Disk Performance](https://pve.proxmox.com/wiki/Performance_Tweaks)
- [QEMU Disk Options](https://qemu.readthedocs.io/en/latest/system/qemu-block-drivers.html)
- [Linux Disk Identification](https://wiki.archlinux.org/title/Persistent_block_device_naming)

---

*Part of the SGC Home Network infrastructure project*
