#!/bin/bash

# --- VARIABLE CONFIGURATION ---
# Change the passwords below for security
DB_ROOT_PASS="PasswordRootSangatRahasia"
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASS="PasswordUserWp123"
NETWORK_NAME="wp-network"

echo "[INFO] Starting App Stack Deployment..."

# 1. Create Docker Network
# Allow containers to communicate with each other using container names (service discovery)
echo "[1/4] Creating Docker Network..."
docker network create $NETWORK_NAME || true

# 2. Running MySQL Container
# Using MySQL 5.7 image which is stable and compatible with many WP versions
echo "[2/4] Running MySQL Database..."
docker run -d \
  --name db-mysql \
  --network $NETWORK_NAME \
  --restart always \
  -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASS \
  -e MYSQL_DATABASE=$DB_NAME \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASS \
  -v db_data:/var/lib/mysql \
  mysql:5.7

# 3. Running WordPress Container
# Connected to 'db-mysql' container using hostname
echo "[3/4] Running WordPress Application..."
docker run -d \
  --name app-wordpress \
  --network $NETWORK_NAME \
  --restart always \
  -e WORDPRESS_DB_HOST=db-mysql:3306 \
  -e WORDPRESS_DB_USER=$DB_USER \
  -e WORDPRESS_DB_PASSWORD=$DB_PASS \
  -e WORDPRESS_DB_NAME=$DB_NAME \
  wordpress:latest

# 4. Running Nginx Container (Reverse Proxy)
# Forwards traffic from server port 80 to WordPress container port 80
# Nginx configuration injected directly (inline config) for practicality
echo "[4/4] Running Nginx Proxy..."
docker run -d \
  --name web-nginx \
  --network $NETWORK_NAME \
  --restart always \
  -p 80:80 \
  -v nginx_conf:/etc/nginx/conf.d \
  nginx:latest \
  /bin/bash -c "echo 'server { listen 80; location / { proxy_pass http://app-wordpress:80; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"

echo ""
echo "[INFO] Waiting for containers to be fully ready..."
echo "[INFO] This may take a few minutes (downloading images and initializing containers)..."

# Wait and show status periodically
for i in {1..30}; do
    sleep 10
    RUNNING=$(docker ps --format '{{.Names}}' | grep -E "db-mysql|app-wordpress|web-nginx" | wc -l)
    echo "[INFO] Progress: $RUNNING/3 containers running... (check $i/30 - ~$((i*10)) seconds elapsed)"
    if [ "$RUNNING" -ge 3 ]; then
        echo "[SUCCESS] All containers are running!"
        break
    fi
done

echo ""
echo "[INFO] Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|db-mysql|app-wordpress|web-nginx"

echo ""
echo "[SUCCESS] Deployment Finished! Website running on Port 80."
echo "[INFO] Please wait a few more minutes for WordPress to complete initialization."
echo "[INFO] You can monitor progress with: docker logs -f app-wordpress"