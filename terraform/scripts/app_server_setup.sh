#!/bin/bash

# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh 
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Nginx 설치
sudo apt-get install -y nginx

# Git 설치
sudo apt-get install -y git

# 방화벽 설정
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# PostgreSQL 클라이언트 설치
sudo apt-get install -y postgresql-client

# 애플리케이션 디렉토리 생성
sudo mkdir -p /opt/app
sudo chown ubuntu:ubuntu /opt/app

# Nginx 기본 설정 생성
sudo tee /etc/nginx/sites-available/app > /dev/null <<EOF
upstream app_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name _;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 타임아웃 설정
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Nginx 설정 활성화
sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# Docker 서비스 시작
sudo systemctl enable docker
sudo systemctl start docker

# 로그 디렉토리 생성
sudo mkdir -p /var/log/app
sudo chown ubuntu:ubuntu /var/log/app

echo "App server setup completed!"