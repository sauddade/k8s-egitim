#!/usr/bin/env bash
# Codespace her başladığında (ilk açılış ve uykudan dönüş) çalışır.
set -uo pipefail

# docker-in-docker daemon'unun hazır olmasını bekle
for _ in $(seq 1 30); do
  docker info >/dev/null 2>&1 && break
  sleep 2
done

bash scripts/start-cluster.sh codespaces
