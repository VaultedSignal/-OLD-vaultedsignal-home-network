# Install SMB

```bash
sudo apt update
sudo apt install -y samba
```

Setup config

```bash
sudo nano /etc/samba/smb.conf
```

Add shares using template

```conf
[temp_share1]
   path = /path/to/nfs/share1
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
```

restart SMB

```bash
sudo systemctl restart smbd
```

Update firewall

```bash
sudo ufw allow samba
```

Acces share over on windows over \\server-ip\share-folder