#!/usr/bin/env bash
# Lab 2.10b — Gerçek kullanıcı senaryosu: "ayse" (grup: dev-team) için istemci sertifikası
# üretir, Kubernetes CSR API ile imzalatır ve kubeconfig'e "ayse@minikube" context'ini ekler.
#
# Kullanım:
#   bash day2/create-user-ayse.sh olustur
#   bash day2/create-user-ayse.sh sil
#
# 🔐 Üretilen ayse.key özel anahtardır — .gitignore ile commit dışı bırakılmıştır.
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  olustur)
    openssl genrsa -out ayse.key 2048
    openssl req -new -key ayse.key -out ayse.csr -subj "/CN=ayse/O=dev-team"

    cat > ayse-csr.yaml << EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ayse
spec:
  request: $(base64 < ayse.csr | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF
    kubectl apply -f ayse-csr.yaml
    kubectl get csr ayse

    # Gerçek hayatta: onaylamadan ÖNCE subject ve gruplar kontrol edilir (system:masters olmamalı!)
    kubectl certificate approve ayse
    sleep 2
    kubectl get csr ayse -o jsonpath='{.status.certificate}' | base64 -d > ayse.crt
    openssl x509 -in ayse.crt -noout -subject -enddate

    kubectl config set-credentials ayse --client-certificate=ayse.crt --client-key=ayse.key --embed-certs=true
    kubectl config set-context ayse@minikube --cluster=minikube --user=ayse --namespace=rbac-demo
    kubectl config get-contexts
    echo ">> Deneyin: kubectl --context=ayse@minikube get pods"
    ;;
  sil)
    kubectl config delete-context ayse@minikube || true
    kubectl config delete-user ayse || true
    kubectl delete csr ayse --ignore-not-found
    kubectl delete clusterrolebinding dev-team-node-reader --ignore-not-found
    kubectl delete clusterrole node-reader --ignore-not-found
    rm -f ayse.key ayse.csr ayse.crt ayse-csr.yaml
    kubectl config use-context minikube
    ;;
  *)
    echo "Kullanım: $0 olustur|sil"; exit 1 ;;
esac
