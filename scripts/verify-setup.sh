#!/usr/bin/env bash
# Kurulum doğrulama (kılavuz Bölüm 7).

echo "=== Docker ==="
docker version --format 'Client: {{.Client.Version}}  Server: {{.Server.Version}}'
docker run --rm hello-world 2>&1 | head -3

echo "=== kubectl / minikube / helm ==="
kubectl version --client
minikube version
helm version --short

echo "=== Cluster ==="
kubectl get nodes -o wide
kubectl get pods -A

echo "=== Calico (NetworkPolicy) ==="
kubectl get pods -n kube-system -l k8s-app=calico-node

echo "=== Ingress Controller ==="
kubectl get pods -n ingress-nginx

echo "=== Metrics Server ==="
kubectl top nodes 2>&1 || echo "Metrics Server henüz hazır değil (birkaç dk bekleyip tekrar deneyin)"

echo "=== Cluster içi DNS + internet erişimi ==="
kubectl run nettest --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  sh -c 'nslookup kubernetes.default >/dev/null && echo DNS-OK; curl -sI https://registry.k8s.io | head -1'

echo
echo "Beklenen: node Ready | calico-node Running | ingress-nginx-controller Running | kubectl top değer döner | DNS-OK + HTTP satırı"
