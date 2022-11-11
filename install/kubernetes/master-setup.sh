#!/bin/bash
# Add Kubernetes repository for Ubuntu 22.04 to all the servers
sudo apt install curl apt-transport-https -y
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Install packages
#-----------------------------------------
sudo apt update
sudo apt install wget curl vim git kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl
# Verify package version
#-----------------------------------------
kubectl version --client && kubeadm version
read -p "Press any key to resume ..." data
sudo swapoff -a 
# Enable kernel modules and configure sysctl.
------------------------------------------
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
read -p "Press any key to resume ..." data
# Install Container runtime
#-----------------------------------------
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
echo "sudo su -"
echo "mkdir -p /etc/containerd"
echo "containerd config default>/etc/containerd/config.toml"
read -p "Run above commands from root in seperate window ..." data
# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
systemctl status containerd
# Initialize control plane
# -------------------------------------
lsmod | grep br_netfilter
read -p "Press any key to resume ..." data
sudo systemctl enable kubelet
# Initialize the machine that will run the control plane components 
# which includes etcd (the cluster database) and the API Server.
# Pull container images:
sudo kubeadm config images pull
#sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
read -p "Press any key to resume ..." data
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl cluster-info
read -p "Press any key to resume ..." data
#Install Kubernetes network plugin
#----------------------------------------
wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f kube-flannel.yml
# Check /etc/containerd/config.toml
echo "Check /etc/containerd/config.toml"
echo "[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]"
echo "  ... "
echo "  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options] "
echo "    SystemdCgroup = true "
echo " Check 114 line !! "
read -p "Check /etc/containerd/config.toml" data
kubectl get pods -n kube-flannel
read -p "Press any key to resume ..." data
#Confirm master node is ready
kubectl get nodes -o wide
#Install ngnix-ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/baremetal/deploy.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
