#!/usr/bin/env bash
# Lab 3.0 — Gün 1'deki uygulamanın (day1/) 3 sürümünü üretir ve minikube'e yükler.
#   v1      : normal
#   v2      : APP_VERSION=2.0
#   v3-bad  : /health 500 döner (hatalı sürüm senaryosu)
set -euo pipefail

cd "$(dirname "$0")/../day1"

docker build -t k8s-demo-app:v1 .
docker build --build-arg APP_VERSION=2.0 -t k8s-demo-app:v2 .
docker build --build-arg APP_VERSION=3.0 --build-arg BROKEN=true -t k8s-demo-app:v3-bad .

if [ -z "${MINIKUBE_ACTIVE_DOCKERD:-}" ]; then
  for tag in v1 v2 v3-bad; do
    minikube image load "k8s-demo-app:$tag"
  done
else
  echo ">> Yol C: imajlar zaten minikube içinde (minikube docker-env aktif)"
fi

minikube image ls | grep k8s-demo-app
