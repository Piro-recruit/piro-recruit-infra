#!/bin/bash

# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# Java 설치 (Jenkins 요구사항)
sudo apt-get install -y openjdk-17-jdk

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Jenkins 설치
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

# Jenkins 사용자를 docker 그룹에 추가
sudo usermod -aG docker jenkins

# Git 설치
sudo apt-get install -y git

# 방화벽 설정
sudo ufw allow 22
sudo ufw allow 8080
sudo ufw --force enable

# Jenkins 서비스 시작
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Jenkins 초기 비밀번호 확인을 위한 파일 권한 설정
sudo chmod 644 /var/lib/jenkins/secrets/initialAdminPassword

# Jenkins 작업 디렉토리 생성
sudo mkdir -p /var/lib/jenkins/workspace
sudo chown jenkins:jenkins /var/lib/jenkins/workspace

# Docker Hub 로그인을 위한 스크립트 생성
sudo tee /home/ubuntu/docker_login.sh > /dev/null <<EOF
#!/bin/bash
# Docker Hub 로그인 스크립트
# 사용법: ./docker_login.sh <username> <password>
echo "\$2" | docker login -u "\$1" --password-stdin
EOF

sudo chmod +x /home/ubuntu/docker_login.sh

echo "Jenkins setup completed!"
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword