## Backup & Recovery

### Configuration Backup

```bash
# Create backup script
nano ~/backup-midway.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Docker configurations
tar -czf $BACKUP_DIR/docker-$DATE.tar.gz /docker

# Backup SSH configuration
tar -czf $BACKUP_DIR/ssh-$DATE.tar.gz /etc/ssh

# Backup network configuration
tar -czf $BACKUP_DIR/network-$DATE.tar.gz /etc/netplan

# Backup firewall rules
ufw status verbose > $BACKUP_DIR/ufw-rules-$DATE.txt

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.txt" -mtime +30 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
chmod +x ~/backup-midway.sh

# Test backup
~/backup-midway.sh

# Add to crontab for weekly backups
crontab -e
# Add: 0 2 * * 0 /home/username/backup-midway.sh
```
