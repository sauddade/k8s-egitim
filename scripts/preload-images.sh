#!/usr/bin/env bash
# Eğitimde kullanılan imajları önceden indirir ve minikube'e yükler
# (sınıfta Docker Hub indirme limitine takılmamak için). Önce: docker login
set -euo pipefail

IMAGES="nginx:1.25 nginx:1.26 busybox:1.36 redis:7-alpine python:3.11-slim nicolaka/netshoot:v0.13 hashicorp/http-echo:1.0"

for img in $IMAGES; do
  echo ">> $img"
  docker pull "$img"
  # Yol C'de (minikube docker-env aktif) imaj zaten minikube içindedir
  if [ -z "${MINIKUBE_ACTIVE_DOCKERD:-}" ]; then
    minikube image load "$img"
  fi
done

# Sadece host'ta kullanılanlar (Gün 1 Docker lab'ları)
docker pull aquasec/trivy:0.58.1
docker pull gcr.io/distroless/python3-debian12:nonroot

echo ">> minikube içindeki imajlar:"
minikube image ls | grep -E "nginx|busybox|netshoot|http-echo|python|redis" || true
