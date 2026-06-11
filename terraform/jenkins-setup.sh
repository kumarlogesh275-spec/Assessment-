#!/bin/bash
# Jenkins server setup — runs once on Ubuntu 24.04 first boot via user_data
set -e
exec > /var/log/jenkins-setup.log 2>&1

echo "=== Starting setup at $(date) ==="

# ── 1. System update ──────────────────────────────────────────────────────────
sudo apt update
sudo apt install -y wget gnupg software-properties-common
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository --yes https://packages.adoptium.net/artifactory/deb
sudo apt update
sudo apt install temurin-21-jdk -y
/usr/bin/java --version


# ── 2. Jenkins ────────────────────────────────────────────────────────────────
# Jenkins

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
sudo systemctl status jenkins

#- DOCKER
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
newgrp docker
sudo chmod 777 /var/run/docker.sock
sudo systemctl restart jenkins
docker run -d --name sonar -p 9000:9000 sonarqube:community

# ── 3. AWS CLI ────────────────────────────────────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# ── 4. kubectl ────────────────────────────────────────────────────────────────
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# ── 5. eksctl ────────────────────────────────────────────────────────────────
ARCH=amd64

curl --silent --location \
"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${ARCH}.tar.gz" \
| tar xz -C /tmp

mv /tmp/eksctl /usr/local/bin

chmod +x /usr/local/bin/eksctl

eksctl version

# ── 6. Helm ───────────────────────────────────────────────────────────────────
# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

helm version

# ── 7. Trivy ──────────────────────────────────────────────────────────────────
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb generic main" \
| tee /etc/apt/sources.list.d/trivy.list

apt-get update -y

apt-get install -y trivy

trivy --version


aws --version
kubectl version --client
eksctl version
helm version
trivy --version
systemctl status jenkins

# # ── 8. Jenkins plugins ────────────────────────────────────────────────────────
# echo "Waiting for Jenkins to start..."
# until curl -s http://localhost:8080/login > /dev/null; do sleep 10; done

# INIT_PASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
# wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar

# java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth "admin:${INIT_PASS}" \
#   install-plugin \
#     git \
#     github \
#     workflow-aggregator \
#     docker-workflow \
#     credentials-binding \
#     aws-credentials \
#     pipeline-stage-view \
#     blueocean \
#     stage-view \
#     -restart

# echo "=== Setup complete at $(date) ==="
# echo "Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
# echo "Initial password: ${INIT_PASS}"