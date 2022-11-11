#!/bin/bash
# Install kubelet, kubeadm and kubectl
# -------------------------------------
sudo apt install curl apt-transport-https -y
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Then install required packages.
---------------------------------------
sudo apt update
sudo apt install wget curl vim git kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version --client && kubeadm version
read -p "Press any key to resume.. " data
sudo swapoff -a 
# Enable kernel modules and configure sysctl.
# --------------------------------------
# Enable kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sudo sysctl --system
# Install Container runtime
# Configure persistent loading of modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter

# Ensure sysctl params are set
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload configs
sudo sysctl --system

# Install required packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
sudo apt update
sudo apt install -y containerd.io

# Configure containerd and start service
echo "sudo su - "
echo "mkdir -p /etc/containerd"
echo "containerd config default>/etc/containerd/config.toml"
read -p "Check /etc/containerd/config.toml" data
# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
systemctl status containerd
# Check /etc/containerd/config.toml
echo "Check /etc/containerd/config.toml"
echo "[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]"
echo "  ... "
echo "  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options] "
echo "    SystemdCgroup = true "
echo " Check 114 line !! "
read -p "Check /etc/containerd/config.toml" data
sudo systemctl restart containerd
