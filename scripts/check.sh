#!/bin/bash
set -e

echo "=== Kubernetes ==="
kubectl get nodes

echo
echo "=== Application ==="
kubectl get pods,svc -n hackathon

echo
echo "=== Gateway API ==="
kubectl get gateway,httproute -n hackathon

echo
echo "=== Prometheus ==="
kubectl get pods -n monitoring

echo
echo "=== Fluentd ==="
kubectl get daemonset fluentd -n hackathon

echo
echo "=== Gateway NodePort ==="
kubectl get svc -n envoy-gateway-system
