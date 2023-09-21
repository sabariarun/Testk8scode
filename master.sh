#! /bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo hostnamectl set-hostname kube-master
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet=1.26.3-00 kubeadm=1.26.3-00 kubectl=1.26.3-00 kubernetes-cni docker.io
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
sudo newgrp docker
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
sudo mkdir /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=All
sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo su - ubuntu -c 'kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml'
