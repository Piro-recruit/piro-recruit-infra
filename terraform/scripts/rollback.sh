#!/bin/bash

# 롤백 스크립트
set -e

APP_NAME="piro-recruiting"

# 현재 활성 컨테이너 확인
RUNNING_CONTAINER=$(docker ps --filter "name=${APP_NAME}" --format "{{.Names}}" | head -1)

if [[ "$RUNNING_CONTAINER" == *"blue"* ]]; then
    CURRENT="blue"
    PREVIOUS="green"
    CURRENT_PORT=8080
    PREVIOUS_PORT=8081
else
    CURRENT="green"
    PREVIOUS="blue"
    CURRENT_PORT=8081
    PREVIOUS_PORT=8080
fi

echo "Rolling back from $CURRENT to $PREVIOUS..."

# 이전 컨테이너가 존재하는지 확인
if ! docker ps -a --filter "name=${APP_NAME}-${PREVIOUS}" --format "{{.Names}}" | grep -q "${APP_NAME}-${PREVIOUS}"; then
    echo "Error: Previous container ${APP_NAME}-${PREVIOUS} not found!"
    exit 1
fi

# 이전 컨테이너 시작
echo "Starting previous container..."
docker start ${APP_NAME}-${PREVIOUS}

# Health check
echo "Checking previous container health..."
for i in {1..30}; do
    if curl -f http://localhost:${PREVIOUS_PORT}/actuator/health > /dev/null 2>&1; then
        echo "Previous container is healthy!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 5
done

# Health check 실패시 에러
if ! curl -f http://localhost:${PREVIOUS_PORT}/actuator/health > /dev/null 2>&1; then
    echo "Previous container health check failed!"
    exit 1
fi

# Nginx 설정 업데이트
echo "Switching traffic back to $PREVIOUS..."
sudo tee /etc/nginx/sites-available/app > /dev/null <<EOF
upstream app_backend {
    server 127.0.0.1:${PREVIOUS_PORT};
}

server {
    listen 80;
    server_name _;

    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }

    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

sudo nginx -t
sudo systemctl reload nginx

# 현재 컨테이너 중지
echo "Stopping current container..."
sleep 5
docker stop ${APP_NAME}-${CURRENT} 2>/dev/null || true

echo "Rollback completed successfully!"
echo "Active container: ${APP_NAME}-${PREVIOUS} (port ${PREVIOUS_PORT})"