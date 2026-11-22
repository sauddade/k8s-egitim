#!/usr/bin/env bash
# Codespace ilk oluşturulduğunda bir kez çalışır.
set -euo pipefail

# Kılavuzdaki ~/k8s-lab yolları Codespaces'te de çalışsın
ln -sfn "$PWD" "$HOME/k8s-lab"

chmod +x scripts/*.sh day2/*.sh 2>/dev/null || true

sudo apt-get update -y >/dev/null
sudo apt-get install -y openssl >/dev/null

echo "Hazır: ~/k8s-lab -> $PWD"
