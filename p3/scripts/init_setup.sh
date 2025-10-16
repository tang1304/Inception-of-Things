#!/bin/bash

echo $'Updating packages and installing wget...\n'
sudo apt-get update
sudo apt-get install -y wget

echo $'Installing docker...\n'
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo $'Checking correct installation of docker...\n'
sudo docker --version

echo $'Installing k3d...\n'
sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
sudo chmod +x /usr/local/bin/k3d

echo $'Checking correct installation of k3d...\n'
k3d --version

echo $'Installing kubectl...\n'
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo $'Checking correct installation of kubectl...\n'
kubectl version --client