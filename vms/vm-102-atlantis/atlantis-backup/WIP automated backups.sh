## Backup Procedures

### RAID Array Backup

```bash
# Backup RAID configuration
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# Save RAID layout
sudo mdadm --detail /dev/md127 > ~/raid-config-$(date +%Y%m%d).txt
```

### Critical Data Backup

```bash
# Create backup script
nano ~/backup-atlantis.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M)

# Create backup directories
mkdir -p $BACKUP_DIR/configs

# Backup important configurations
sudo cp /etc/fstab $BACKUP_DIR/configs/fstab-$DATE
sudo cp /etc/samba/smb.conf $BACKUP_DIR/configs/smb.conf-$DATE
sudo mdadm --detail --scan > $BACKUP_DIR/configs/mdadm-$DATE.conf
sudo cp /etc/mdadm/mdadm.conf $BACKUP_DIR/configs/mdadm.conf-$DATE

# Backup file lists (for recovery verification)
find /drives/alfheim -type f > $BACKUP_DIR/file-list-alfheim-$DATE.txt
find /drives/aincrad -type f > $BACKUP_DIR/file-list-aincrad-$DATE.txt

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.txt" -mtime +30 -delete
find $BACKUP_DIR/configs -name "*" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Make executable and add to cron:

```bash
chmod +x ~/backup-atlantis.sh

# Add to crontab (weekly backups on Sunday at 2 AM)
crontab -e
# Add: 0 2 * * 0 /home/username/backup-atlantis.sh
```