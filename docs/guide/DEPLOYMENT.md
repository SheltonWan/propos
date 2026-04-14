# 部署配置方案

> **文档版本**: v1.0
> **更新日期**: 2026-04-08
> **适用阶段**: Phase 1（单机部署）

---

## 一、架构概览

```
┌─────────────────────────────────────────┐
│              Host Server                │
│                                         │
│  ┌─────────┐  ┌──────────┐  ┌────────┐ │
│  │  Dart   │  │PostgreSQL│  │ Nginx  │ │
│  │ Backend │  │   15+    │  │ Proxy  │ │
│  │ :8080   │  │  :5432   │  │ :443   │ │
│  └────┬────┘  └────┬─────┘  └───┬────┘ │
│       │            │            │       │
│       └────────────┴────────────┘       │
│             Docker Compose              │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  /data/uploads (文件存储 Volume)  │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 二、Dockerfile（后端）

```dockerfile
# backend/Dockerfile
# ---- 构建阶段 ----
FROM dart:3.6 AS build

WORKDIR /app

# 先复制依赖描述，利用 Docker 缓存层
COPY backend/pubspec.yaml backend/pubspec.lock ./backend/
COPY packages/ ./packages/

WORKDIR /app/backend
RUN dart pub get

# 复制后端源码
COPY backend/ ./

# 编译为 AOT（生产模式）
RUN dart compile exe bin/server.dart -o bin/server

# ---- 运行阶段 ----
FROM debian:bookworm-slim

# 安装运行时依赖（SSL + CA 证书）
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 从构建阶段复制编译产物
COPY --from=build /app/backend/bin/server /app/server

# 非 root 用户运行
RUN groupadd -r propos && useradd -r -g propos propos
USER propos

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

ENTRYPOINT ["/app/server"]
```

---

## 三、docker-compose.yml

```yaml
# docker-compose.yml
version: "3.9"

services:
  # ---- PostgreSQL ----
  postgres:
    image: postgres:15-alpine
    container_name: propos-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: propos
      POSTGRES_USER: ${DB_USER:-propos}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?DB_PASSWORD is required}
    volumes:
      - pg_data:/var/lib/postgresql/data
      # 初始化脚本（DDL + seed）
      - ./backend/migrations:/docker-entrypoint-initdb.d:ro
    ports:
      - "${DB_PORT:-5432}:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-propos}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ---- Dart Backend ----
  backend:
    build:
      context: .
      dockerfile: backend/Dockerfile
    container_name: propos-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DATABASE_URL: postgres://${DB_USER:-propos}:${DB_PASSWORD}@postgres:5432/propos
      JWT_SECRET: ${JWT_SECRET:?JWT_SECRET is required}
      JWT_EXPIRES_IN_HOURS: ${JWT_EXPIRES_IN_HOURS:-24}
      FILE_STORAGE_PATH: /data/uploads
      ENCRYPTION_KEY: ${ENCRYPTION_KEY:?ENCRYPTION_KEY is required}
      APP_PORT: "8080"
      CORS_ORIGINS: ${CORS_ORIGINS:-*}
      LOG_LEVEL: ${LOG_LEVEL:-info}
      MAX_UPLOAD_SIZE_MB: ${MAX_UPLOAD_SIZE_MB:-50}
    volumes:
      - file_storage:/data/uploads
    ports:
      - "8080:8080"

  # ---- Nginx 反向代理（HTTPS 终止） ----
  nginx:
    image: nginx:alpine
    container_name: propos-nginx
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./deploy/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./deploy/nginx/ssl:/etc/nginx/ssl:ro
      - file_storage:/data/uploads:ro  # 静态文件直接由 Nginx 服务
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  pg_data:
    driver: local
  file_storage:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${FILE_STORAGE_HOST_PATH:-/data/propos-uploads}
```

---

## 四、Nginx 配置

```nginx
# deploy/nginx/nginx.conf
worker_processes auto;
events { worker_connections 1024; }

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # 日志
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    # 安全头
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 文件上传限制
    client_max_body_size 50m;

    # HTTPS → HTTP upgrade
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name propos.example.com;

        ssl_certificate     /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        # API 代理
        location /api/ {
            proxy_pass http://backend:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket（如需 SSE）
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # 静态文件（Flutter Web 产物）
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }

        # 健康检查
        location /health {
            access_log off;
            return 200 'ok';
        }
    }
}
```

---

## 五、环境变量文件模板

```bash
# .env.example（复制为 .env 后填入实际值）
# ── 必填（缺失则服务拒绝启动）──
DB_USER=propos
DB_PASSWORD=                    # PostgreSQL 密码
JWT_SECRET=                     # ≥32 位随机字符串
ENCRYPTION_KEY=                 # 32 字节 AES-256 密钥（hex）

# ── 可选 ──
DB_PORT=5432
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_HOST_PATH=/data/propos-uploads
CORS_ORIGINS=https://propos.example.com
LOG_LEVEL=info
MAX_UPLOAD_SIZE_MB=50
```

---

## 六、部署命令

```bash
# 首次部署
cp .env.example .env            # 填写实际值
docker compose up -d --build

# 查看日志
docker compose logs -f backend

# 数据库迁移（在容器内执行）
docker compose exec postgres psql -U propos -d propos -f /docker-entrypoint-initdb.d/001_init.sql

# 更新后端
docker compose build backend
docker compose up -d backend    # 零停机滚动更新（单实例重启约 3-5s）

# 备份数据库
docker compose exec postgres pg_dump -U propos propos > backup_$(date +%Y%m%d).sql
```

---

## 七、Flutter Web 部署

```bash
# 在本地构建 Flutter Web 产物
cd frontend
flutter build web --release --base-href /

# 复制到 Nginx 容器的静态文件目录
# 方式一：构建时 COPY 到 nginx 镜像
# 方式二：通过 volume 挂载
scp -r build/web/* deploy/nginx/html/
docker compose restart nginx
```

---

## 八、监控与运维

| 监控项 | 方式 | 告警阈值 |
|--------|------|---------|
| 后端存活 | `GET /api/health` | 连续 3 次失败 |
| 数据库连接 | `pg_isready` | 连续 5 次失败 |
| 磁盘空间 | `df -h` on upload volume | > 85% |
| 后端内存 | Docker stats | > 512MB |
| 定时任务失败 | `job_execution_logs` 表 | `status = 'retry_exhausted'` |

---

## 九、注意事项

### 9.1 migrations 目录挂载路径

`docker-compose.yml` 将 `./backend/migrations` 挂载到 PostgreSQL 容器的 `/docker-entrypoint-initdb.d/`。
`init_local_postgres.sh` 也读取同一目录（`MIGRATIONS_DIR` 默认值为 `backend/migrations`）。
**两者指向同一路径，不需要维护两套脚本。**

> 当前 `backend/migrations/` 只有 `.gitkeep`，DDL 就位前两种方式均会跳过。

### 9.2 `docker-entrypoint-initdb.d` 仅在数据卷首次创建时执行

PostgreSQL 官方镜像只在 `pg_data` 数据卷**为空**时才会执行 `/docker-entrypoint-initdb.d/` 下的脚本。
已有数据的情况下重启容器**不会**重新执行 DDL。

如需在已有实例上补跑迁移脚本，有两种方式：

```bash
# 方式一：通过 Docker Compose exec 在容器内执行
docker compose exec postgres \
  psql -U propos -d propos -f /docker-entrypoint-initdb.d/002_add_indexes.sql

# 方式二：通过 init_local_postgres.sh 从宿主机执行（需 5432 端口暴露）
bash scripts/init_local_postgres.sh --skip-migrations  # 跳过已执行的，只跑新增的
```

### 9.3 `init_local_postgres.sh` 与 Docker Compose 的配合方式

| 场景 | 推荐操作 |
|------|----------|
| 首次启动 Docker Compose | `docker compose up -d` 自动执行 DDL（数据卷为空时）|
| 补跑新增迁移脚本 | `docker compose exec postgres psql ...` 或 `init_local_postgres.sh` |
| 重置本地数据库 | `docker compose down -v && docker compose up -d`（销毁数据卷重建）|
| 纯宿主机 PostgreSQL 开发 | `bash scripts/init_local_postgres.sh [--seed]` |

### 9.4 `init_local_postgres.sh` 的幂等性边界

脚本对「角色和数据库创建」是**幂等**的（`WHERE NOT EXISTS` 保护）。
对「migration SQL 执行」**不幂等**——同一个 `.sql` 文件运行两次会报重复创建错误。
因此迁移脚本本身应在 DDL 语句中使用 `IF NOT EXISTS`，例如：

```sql
CREATE TABLE IF NOT EXISTS buildings ( ... );
CREATE INDEX IF NOT EXISTS idx_buildings_type ON buildings(type);
```

### 9.5 生产环境不要使用 `init_local_postgres.sh`

该脚本默认密码为 `ChangeMe_2026!`，设计用于本地开发环境。
生产环境数据库初始化应通过 CI/CD 流水线或运维工具执行，密钥通过 `ADMIN_DATABASE_URL` 注入，**不得**使用默认值。
