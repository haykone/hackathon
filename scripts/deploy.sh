#!/bin/bash
set -e

echo "=== Hackathon deployment ==="

echo "[1/6] Installing Calico..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/calico.yaml

echo "[2/6] Allowing workloads on single control-plane node..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

echo "[3/6] Installing Envoy Gateway..."
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.9.2/install.yaml

echo "[4/6] Deploying application..."
kubectl apply -f kubernetes/app.yaml

echo "Waiting for Envoy Gateway..."
kubectl wait --for=condition=Available deployment/envoy-gateway \
  -n envoy-gateway-system --timeout=180s

kubectl apply -f kubernetes/gateway-api.yaml

echo "[5/6] Installing Fluentd..."
kubectl apply -f logging/fluentd.yaml

echo "[6/6] Installing Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace \
  --set alertmanager.enabled=false \
  --set prometheus-pushgateway.enabled=false \
  --set server.persistentVolume.enabled=false

echo
echo "=== Deployment complete ==="
kubectl get nodes
kubectl get pods -A
kubectl get gateway,httproute -n hackathon
