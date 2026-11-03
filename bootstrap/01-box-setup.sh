#!/bin/bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y git curl wget unzip jq gnupg ca-certificates fontconfig openjdk-21-jre docker.io python3-yaml

# AWS CLI
curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# Terraform
wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

# Jenkins (2026 signing key)
sudo mkdir -p /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update
sudo apt-get install -y terraform jenkins

# kubectl and helm
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
sudo systemctl enable --now docker
sudo systemctl restart jenkins
echo "DONE. Close this terminal and reconnect so the docker group applies."
echo "Jenkins password:"; sudo cat /var/lib/jenkins/secrets/initialAdminPassword
