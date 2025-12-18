# Expanding a VM drive on proxmox

Check current disk and partition layout

```bash
lsblk
```

Expand the disk

```bash
pvresize /dev/sdX#   # expand physical volume
lvextend -l +100%FREE /dev/<vg_name>/<lv_name>  # expand logical volume
```

expand the file system

```bash
resize2fs /dev/<vg_name>/<lv_name>
```

Check currenewnt disk and partition layout

```bash
lsblk
```
