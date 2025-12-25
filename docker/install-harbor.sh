#!/usr/bin/env bash
set -e

root=$(pwd)

### ================== 可修改参数 ==================
HARBOR_VERSION="v2.14.1"
HARBOR_HTTP_PORT=8088
HARBOR_ADMIN_PASSWORD="root"
HARBOR_DATA_DIR="/data/harbor"
HARBOR_DB_PASSWORD="root123"
### ================================================

echo ">>> Harbor ${HARBOR_VERSION} install (docker compose v2)"

# 1️⃣ 获取内网 IP（非 127.0.0.1）
INTERNAL_IP=$(hostname -I | awk '{print $1}')
echo ">>> Detected internal IP: ${INTERNAL_IP}"

# 2️⃣ 检查 Docker 和 Compose v2
command -v docker >/dev/null || { echo "Docker not found"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "docker compose v2 not found"; exit 1; }

# 3️⃣ 下载 Harbor 离线包
if [ ! -f harbor-offline-installer-${HARBOR_VERSION}.tgz ]; then
  echo ">>> Download Harbor ${HARBOR_VERSION}"
  wget --no-check-certificate --no-cache https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-offline-installer-${HARBOR_VERSION}.tgz
fi

# 4️⃣ 解压
rm -rf $root/harbor
tar zxvf harbor-offline-installer-${HARBOR_VERSION}.tgz
cd harbor

# 7️⃣ 自动创建虚拟证书文件，避免 prepare 报错
SSL_DIR="$root/harbor/ssl"
mkdir -p ${SSL_DIR}

# 生成 harbor.yml
echo ">>> Generate harbor.yml for HTTP-only..."
HARBOR_YML="harbor.yml"
cat > $HARBOR_YML <<EOF
hostname: $INTERNAL_IP

protocol: http

http:
  port: $HARBOR_HTTP_PORT

https:
  port: 443
  certificate: $SSL_DIR/server.crt
  private_key: $SSL_DIR/server.key

harbor_admin_password: $HARBOR_ADMIN_PASSWORD

database:
  password: $HARBOR_DB_PASSWORD
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0

data_volume: $HARBOR_DATA_DIR

jobservice:
  max_job_workers: 10
  max_job_duration_hours: 24
  job_loggers:
    - STD_OUTPUT
    - FILE
  logger_sweeper_duration: 1

proxy_cache:
  enabled: true
  registries:
    - name: dockerhub
      url: https://registry-1.docker.io
      username:
      password:

log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor

notification:
  webhook_job_max_retry: 3
  webhook_job_http_client_timeout: 60

upload_purging:
  enabled: true
  age: 168h
  interval: 24h
  dryrun: false
  
cache:
  enabled: false
  expire_hours: 24
EOF

# 9️⃣ 创建数据目录
mkdir -p ${HARBOR_DATA_DIR}

# 🔟 运行 prepare（生成配置）
echo ">>> Run prepare"
./prepare --with-trivy

# 1️⃣1️⃣ 启动 Harbor
echo ">>> Start Harbor"
docker compose down -v || true
docker compose up -d

echo ""
echo "=================================================="
echo "Harbor v2.14.1 installed successfully"
echo "URL: http://${INTERNAL_IP}:${HARBOR_HTTP_PORT}"
echo "Username: admin"
echo "Password: ${HARBOR_ADMIN_PASSWORD}"
echo "=================================================="
