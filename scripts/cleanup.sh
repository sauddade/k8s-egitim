#!/usr/bin/env bash
# Gün sonu temizliği (kılavuz Bölüm 12). Sadece eğitim namespace'lerini siler.
#
# Kullanım: bash scripts/cleanup.sh gun1|gun2|gun3
set -euo pipefail

GUN="${1:-}"
case "$GUN" in
  gun1) NS="gun1 egitim my-lab" ;;
  gun2) NS="gun2 netpol-demo rbac-demo day2-lab ctf" ;;   # hostpath-demo Gün 3'te kullanılacak
  gun3) NS="gun3 bluegreen quota-demo psa-demo hostpath-demo final-project" ;;
  *) echo "Kullanım: $0 gun1|gun2|gun3"; exit 1 ;;
esac

kubectl config set-context --current --namespace=default

if [ "$GUN" = "gun3" ]; then
  helm list -A
  echo ">> Kalan Helm release varsa: helm uninstall <ad> -n <namespace>"
fi

# shellcheck disable=SC2086
kubectl delete namespace $NS --ignore-not-found

if [ "$GUN" = "gun2" ]; then
  kubectl delete pv static-pv --ignore-not-found
  kubectl delete clusterrolebinding dev-team-node-reader --ignore-not-found
  kubectl delete clusterrole node-reader --ignore-not-found
  kubectl delete csr ayse --ignore-not-found
fi

kubectl get ns
