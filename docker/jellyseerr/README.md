# Work in progress README

[Official documentation](https://docs.seerr.dev/)

Port:5055 

## Updating:

Pull the latest image:

```bash
docker compose pull jellyseerr.yaml
```

Then, restart all services defined in the Compose file:

```bash
sudo docker compose -f jellyseerr.yaml up -d
```


Jellyseerr cant find sonarr etc prob cauze VPN stuff need to look in to that