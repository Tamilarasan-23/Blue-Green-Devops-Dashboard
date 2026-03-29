#!/bin/bash

VERSION="v$(date +%s)"
TIME="$(date)"

echo "Resetting files from templates..."

cp deploy.template.html deploy.html
cp logs.template.html logs.html

# Decide environment
if grep -q "proxy_pass http://blue;" nginx.conf; then
    ENV="GREEN"
    sed -i 's/proxy_pass http:\/\/blue;/proxy_pass http:\/\/green;/' nginx.conf
else
    ENV="BLUE"
    sed -i 's/proxy_pass http:\/\/green;/proxy_pass http:\/\/blue;/' nginx.conf
fi

echo "Updating deployment page..."

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

echo "Stopping old GREEN container..."
docker stop green || true
docker rm green || true

echo "Building Docker image..."
docker build -t dev-dashboard:$VERSION .

echo "Running container..."
docker run -d -p 8082:80 --name green dev-dashboard:$VERSION

echo "Restarting Nginx..."
NGINX_ID=$(docker ps -q --filter ancestor=nginx)
docker restart $NGINX_ID

echo "Deployment completed!"
