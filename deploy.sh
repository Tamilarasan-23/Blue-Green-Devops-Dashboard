#!/bin/bash

echo "Stopping old GREEN container..."
docker stop green || true
docker rm green || true

echo "Building new version..."
docker build --build-arg BUILD_TIME="$(date)" -t dev-dashboard:v2 .

echo "Running GREEN container..."
docker run -d -p 8082:80 --name green dev-dashboard:v2

echo "Switching traffic..."

if grep -q "proxy_pass http://blue;" nginx.conf; then
    sed -i 's/proxy_pass http:\/\/blue;/proxy_pass http:\/\/green;/' nginx.conf
    echo "Switched to GREEN"
else
    sed -i 's/proxy_pass http:\/\/green;/proxy_pass http:\/\/blue;/' nginx.conf
    echo "Switched to BLUE"
fi

NGINX_ID=$(docker ps -q --filter ancestor=nginx)
docker restart $NGINX_ID

echo "Deployment completed!"
