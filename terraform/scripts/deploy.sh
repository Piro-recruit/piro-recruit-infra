#!/bin/bash

# Blue-Green 배포 스크립트 (App Server에서 실행)

set -e

APP_NAME="piro-recruiting"
DOCKER_IMAGE="$1"
NEW_VERSION="$2"

if [ -z "$DOCKER_IMAGE" ] || [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <docker_image> <version>"
    echo "Example: $0 myrepo/piro-recruiting:latest v1.0.0"
    exit 1
fi

# 현재 실행 중인 컨테이너 확인
CURRENT_CONTAINER=$(docker ps --filter "name=${APP_NAME}" --format "{{.Names}}" | head -1)

if [[ "$CURRENT_CONTAINER" == *"blue"* ]]; then
    ACTIVE="blue"
    STANDBY="green"
    ACTIVE_PORT=8080
    STANDBY_PORT=8081
else
    ACTIVE="green"
    STANDBY="blue"
    ACTIVE_PORT=8081
    STANDBY_PORT=8080
fi

echo "Current active: $ACTIVE (port $ACTIVE_PORT)"
echo "Deploying to: $STANDBY (port $STANDBY_PORT)"

# 새 이미지 pull
echo "Pulling new image: $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE

# Standby 컨테이너 중지 및 제거
echo "Stopping standby container..."
docker stop ${APP_NAME}-${STANDBY} 2>/dev/null || true
docker rm ${APP_NAME}-${STANDBY} 2>/dev/null || true

# 새 컨테이너 시작
echo "Starting new container..."
docker run -d \
    --name ${APP_NAME}-${STANDBY} \
    --restart unless-stopped \
    -p ${STANDBY_PORT}:8080 \
    -e SPRING_PROFILES_ACTIVE=prod \
    -e DB_HOST="${DB_HOST}" \
    -e DB_PORT="${DB_PORT}" \
    -e DB_NAME="${DB_NAME}" \
    -e DB_USERNAME="${DB_USERNAME}" \
    -e DB_PASSWORD="${DB_PASSWORD}" \
    --log-driver=json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    $DOCKER_IMAGE

# Health check
echo "Waiting for application to start..."
for i in {1..30}; do
    if curl -f http://localhost:${STANDBY_PORT}/actuator/health > /dev/null 2>&1; then
        echo "Application is healthy!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

# Health check 실패시 롤백
if ! curl -f http://localhost:${STANDBY_PORT}/actuator/health > /dev/null 2>&1; then
    echo "Health check failed! Rolling back..."
    docker stop ${APP_NAME}-${STANDBY}
    docker rm ${APP_NAME}-${STANDBY}
    exit 1
fi

# Nginx 설정 업데이트 (Blue-Green 스위치)
echo "Switching traffic to $STANDBY..."
sudo tee /etc/nginx/sites-available/app > /dev/null <<EOF
upstream app_backend {
    server 127.0.0.1:${STANDBY_PORT};
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

# Nginx 설정 검증 및 재시작
sudo nginx -t
sudo systemctl reload nginx

# 이전 컨테이너 중지 (롤백을 위해 바로 삭제하지 않음)
echo "Stopping old container ($ACTIVE)..."
sleep 5  # 트래픽 전환 대기
docker stop ${APP_NAME}-${ACTIVE} 2>/dev/null || true

echo "Deployment completed successfully!"
echo "New active container: ${APP_NAME}-${STANDBY} (port ${STANDBY_PORT})"
echo "Previous container ${APP_NAME}-${ACTIVE} is stopped but not removed for rollback purposes"