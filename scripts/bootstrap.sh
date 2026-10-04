#!/bin/bash
set -e

echo "=== Kubernetes bootstrap for Ubuntu 24.04 ==="

sudo swapoff -a
sudo sed -i '/\/swap.img/s/^/#/' /etc/fstab

cat <<MOD | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
MOD

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<SYSCTL | sudo tee /etc/sysctl.d/99-kubernetes.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
SYSCTL

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y ca-certificates curl gpg containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo
echo "Kubernetes control plane initialized."
echo "Now install Helm and run: ./scripts/deploy.sh"
