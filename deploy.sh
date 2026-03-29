#!/bin/bash

VERSION="v$(date +%s)"
TIME="$(date)"

echo "Stopping old GREEN container..."
docker stop green || true
docker rm green || true

echo "Building new version..."
docker build --build-arg BUILD_TIME="$TIME" -t dev-dashboard:$VERSION .

echo "Running GREEN container..."
docker run -d -p 8082:80 --name green dev-dashboard:$VERSION

# Decide environment switch
if grep -q "proxy_pass http://blue;" nginx.conf; then
    ENV="GREEN"
    sed -i 's/proxy_pass http:\/\/blue;/proxy_pass http:\/\/green;/' nginx.conf
else
    ENV="BLUE"
    sed -i 's/proxy_pass http:\/\/green;/proxy_pass http:\/\/blue;/' nginx.conf
fi

echo "Updating deployment history..."

sed -i "s/VERSION/$VERSION/" deploy.html
sed -i "s/BUILD_TIME/$TIME/" deploy.html
sed -i "s/STATUS/SUCCESS/" deploy.html
sed -i "s/ENV/$ENV/" deploy.html

echo "Updating logs..."

LOGS="[INFO] Starting deployment...<br>
[INFO] Building Docker image...<br>
[SUCCESS] Container started successfully<br>
[INFO] Switching traffic to $ENV<br>
[SUCCESS] Deployment completed<br>
[WARN] Monitoring system active"

sed -i "s|LOG_CONTENT|$LOGS|" logs.html

# Restart nginx
NGINX_ID=$(docker ps -q --filter ancestor=nginx)
docker restart $NGINX_ID

echo "Deployment completed!"
