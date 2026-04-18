services:
  arcane-agent:
    image: ghcr.io/getarcaneapp/arcane-headless:latest
    container_name: arcane-agent
    restart: unless-stopped
    environment:
      - AGENT_MODE=true
      - EDGE_TRANSPORT=poll
      - AGENT_TOKEN=arc_f161df99f4aae4055c63637303d60cbbc123bcb844529c4910fa2e0c7138fd6d
      - MANAGER_API_URL=http://192.168.2.201:3552
    ports:
      - "3553:3553"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - arcane-data:/app/data

volumes:
  arcane-data: