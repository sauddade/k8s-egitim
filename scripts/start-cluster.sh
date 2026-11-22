#!/usr/bin/env bash
# Standart eğitim cluster'ını başlatır: Calico CNI + metrics-server + ingress
#
# Kullanım:
#   bash scripts/start-cluster.sh            # standart profil (16 GB RAM)
#   bash scripts/start-cluster.sh dusuk      # düşük kaynak profili (8 GB RAM)
#
# Yol C (Hyper-V / VirtualBox) için sürücüyü ortam değişkeniyle verin:
#   MINIKUBE_DRIVER=hyperv bash scripts/start-cluster.sh
set -euo pipefail

PROFIL="${1:-standart}"
case "$PROFIL" in
  standart)   CPUS=4; MEM=6g ;;
  dusuk)      CPUS=2; MEM=3500m ;;
  codespaces) CPUS=3; MEM=6g ;;
  *) echo "Kullanım: $0 [standart|dusuk]"; exit 1 ;;
esac

DRIVER="${MINIKUBE_DRIVER:-docker}"

# Kurumsal kök sertifika ~/.minikube/certs altına konduysa cluster'a taşı (kılavuz Bölüm 1.4)
EXTRA=""
if [ -d "$HOME/.minikube/certs" ] && [ -n "$(ls -A "$HOME/.minikube/certs" 2>/dev/null)" ]; then
  EXTRA="--embed-certs"
fi

if minikube status >/dev/null 2>&1; then
  echo ">> Cluster zaten çalışıyor."
else
  echo ">> minikube başlatılıyor (driver=$DRIVER, cpus=$CPUS, memory=$MEM, cni=calico)..."
  # shellcheck disable=SC2086
  minikube start --driver="$DRIVER" --cni=calico --cpus="$CPUS" --memory="$MEM" --disk-size=30g $EXTRA
fi

echo ">> Eklentiler etkinleştiriliyor..."
minikube addons enable metrics-server
minikube addons enable ingress

echo ">> Durum:"
kubectl get nodes
kubectl get pods -n kube-system -l k8s-app=calico-node
echo ">> Hazır. Doğrulama için: bash scripts/verify-setup.sh"
