#!/usr/bin/env bash
# Self-Locally: 1-Command Startup for kosync + shlink + gogs + dnscrypt-proxy
# Combined Footprint: ~119 MB RAM | ~140 MB Disk | Zero external databases
set -euo pipefail

echo "==> [1/4] Launching kosync (KOReader sync, ~18 MB RAM)..."
docker run -d \
  --name kosync \
  --restart unless-stopped \
  -p 3000:3000 \
  -v kosync_data:/app/data \
  ghcr.io/nperez0111/koreader-sync:latest

echo "==> [2/4] Launching shlink (Shortlink host, ~38 MB RAM)..."
docker run -d \
  --name shlink \
  --restart unless-stopped \
  -p 8080:8080 \
  -e DEFAULT_DOMAIN=localhost:8080 \
  -e IS_HTTPS_ENABLED=false \
  -e DB_DRIVER=sqlite \
  -v shlink_data:/etc/shlink/data \
  shlinkio/shlink:stable

echo "==> [3/4] Launching gogs (Git server, ~38 MB RAM)..."
docker run -d \
  --name gogs \
  --restart unless-stopped \
  -p 10080:3000 \
  -p 10022:22 \
  -v gogs_data:/data \
  gogs/gogs:latest

echo "==> [4/4] Launching dnscrypt-proxy (Encrypted + cached DNS, ~25 MB RAM)..."
# If host port 53 is occupied by systemd-resolved or local nameserver, use -p 5053:53
DNS_PORT="53"
if ss -tuln | grep -q ':53 '; then
  echo "    Port 53 occupied on host. Mapping dnscrypt-proxy to 5053."
  DNS_PORT="5053"
fi

docker run -d \
  --name dnscrypt-proxy \
  --restart unless-stopped \
  -p "${DNS_PORT}:53/udp" \
  -p "${DNS_PORT}:53/tcp" \
  klutchell/dnscrypt-proxy:latest

echo "==> All 4 services running successfully! Memory footprint check:"
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" kosync shlink gogs dnscrypt-proxy
