# PropOS 腾讯云轻量服务器部署指南

> **文档版本**：v1.3  
> **更新日期**：2026-04-27  
> **目标服务器**：腾讯云轻量应用服务器，公网 IP `111.230.112.246`，OpenCloudOS 8，Docker 26.1.3  
> **适用范围**：backend（Dart/Shelf AOT）+ admin（Vue 3 SPA）单机部署

---

## 一、整体架构

```
本地开发机
  ├── scripts/setup_server.sh     ← 首次执行：配置免密 SSH + 初始化服务器
  ├── backend/deploy.sh           ← 每次部署后端时执行
  └── admin/deploy.sh             ← 每次部署前端时执行

服务器（Docker network: propos-net）
  ├── propos-postgres:5432        ← PostgreSQL 15，数据卷持久化
  ├── propos-backend:8080         ← Dart AOT 二进制，从腾讯云 TCR 拉取镜像
  └── propos-nginx:80             ← Nginx，/ 托管 admin SPA，/api/ 反代 backend
```

**请求链路**：

```
浏览器 → http://111.230.112.246
  ├── GET /          → Nginx 静态文件（/opt/propos/admin-dist/）
  ├── GET /api/...   → Nginx 反代 → propos-backend:8080
  └── propos-backend → propos-postgres:5432
```

---

## 二、前置条件

### 本地机器

| 工具 | 最低版本 | 用途 |
|------|---------|------|
| Docker Desktop | 24+ | 构建 backend 镜像 |
| pnpm | 8+ | 构建 admin 静态文件 |
| rsync | 任意 | 同步 admin dist 到服务器 |
| ssh / ssh-keygen | OpenSSH 8+ | 免密登录服务器 |
| sshpass | 任意 | **可选**：自动传递 SSH 密码，免交互推送公钥（`brew install hudochenkov/sshpass/sshpass`） |

### 镜像仓库（腾讯云 TCR）

- 仓库地址：`ccr.ccs.tencentyun.com/ephnic/propos_backend`
- TCR 凭据统一存储在项目根目录 `.deploy.env`（已加入 `.gitignore`，严禁提交）：
  ```bash
  cp .deploy.env.example .deploy.env
  # 填写 SERVER_SSH_PASSWORD（可选）、TCR_USER、TCR_PASSWORD
  ```
- 凭据配置后，`backend/deploy.sh`（本地 push）和 `scripts/setup_server.sh`（服务器 pull）**自动登录**，无需手动执行 `docker login`

### 服务器防火墙

在腾讯云控制台 **防火墙规则** 中放行以下端口：

| 端口 | 协议 | 说明 |
|------|------|------|
| 22 | TCP | SSH |
| 80 | TCP | **统一对外入口**：admin SPA + 所有 `/api/` 请求（Nginx 反代到 backend） |
| 8080 | TCP | backend 直连端口，**推荐保持内网仅供 Nginx 使用，不对外开放**（见下方说明） |

> **关于端口 8080**：admin、Flutter App、uni-app 三端均应将 API Base URL 配置为 `http://111.230.112.246`（端口 80），由 Nginx 统一将 `/api/` 路径反代到 `propos-backend:8080`（Docker 内网通信）。端口 8080 无需在防火墙中对外放行。  
> 若因调试需要直连 8080，可临时放行后验证，验证完毕及时关闭。

---

## 三、Phase 0 — 首次初始化（仅执行一次）

### 3.1 执行初始化脚本

```bash
# 在项目根目录执行
bash scripts/setup_server.sh
```

脚本执行顺序：

1. **生成 SSH 密钥**（若 `~/.ssh/id_ed25519` 不存在则自动生成）
2. **推送公钥**到服务器：
   - 若密钥认证已生效（非首次执行）→ **自动跳过**
   - 若 `.deploy.env` 中配置了 `SERVER_SSH_PASSWORD` 且本地安装了 `sshpass` → **全自动推送，无需交互**
   - 否则 → 提示手动输入一次服务器密码
3. **写入 SSH 配置**：`~/.ssh/config` 中添加 `Host propos-server` 别名
4. **验证免密登录**：`ssh propos-server echo ok`
5. **配置服务器端 TCR 登录凭据**：优先从 `.deploy.env` 读取 `TCR_USER`/`TCR_PASSWORD` 自动配置；若未配置则交互式输入，在服务器执行 `docker login ccr.ccs.tencentyun.com`，凭据持久化至 `/root/.docker/config.json`
6. **远程创建 Docker 网络**：`propos-net`
7. **远程启动 PostgreSQL**：容器 `propos-postgres`，数据卷 `propos-pgdata`
8. **自动生成生产环境 `.env`**：直接在服务器 `/opt/propos/.env` 写入正确生产配置，`JWT_SECRET` / `ENCRYPTION_KEY` 随机生成，`DATABASE_URL` host 使用容器名 `propos-postgres`

### 3.2 确认生产环境变量（脚本已自动生成）

`setup_server.sh` 执行完毕后，所有**必填项均已自动写入**服务器 `/opt/propos/.env`（文件权限 600），无需手动填写。

| 字段 | 生成方式 | 与本地 .env 的差异 |
|------|---------|-------------------|
| `DATABASE_URL` | 自动生成，host 为 `propos-postgres`（容器名） | 本地为 `localhost` |
| `JWT_SECRET` | `openssl rand -base64 48` 随机生成 | 本地为固定测试值 |
| `ENCRYPTION_KEY` | `openssl rand -hex 32` 随机生成 | 本地为固定测试值 |
| `FILE_STORAGE_PATH` | `/data/uploads`（容器挂载卷） | 本地为 `.local/uploads` |
| `CORS_ORIGINS` | `http://111.230.112.246` | 本地为 `localhost:3000,5173` |
| `LOG_LEVEL` | `info` | 本地为 `debug` |
| `ALLOW_TEST_ENDPOINTS` | `false`（硬编码，不可更改） | 本地为 `true` |
| `SMTP_*` | 从 `.deploy.env` 自动读取，与本地统一 | 相同 |

> **重要**：初始化完成后立即备份生产密钥：
> ```bash
> ssh propos-server cat /opt/propos/.env
> ```

### 3.3 运行数据库迁移

backend 容器首次启动后，在**服务器**上执行迁移：

```bash
# 登录服务器
ssh propos-server

# 检查 backend 容器是否运行
docker ps | grep propos-backend

# 在容器内执行迁移（backend 支持 migrate 子命令，或手动导入 SQL）
# 方法一：若 backend 支持自动迁移（启动时自动执行）则无需操作
# 方法二：手动导入迁移文件
for f in /opt/propos/migrations/*.sql; do
  echo "运行: $f"
  docker exec propos-postgres psql -U propos -d propos -f /dev/stdin < "$f"
done
```

---

## 四、Phase 1 — 部署后端（backend）

### 4.1 脚本说明

```bash
# 在项目根目录或 backend/ 目录执行
bash backend/deploy.sh
```

脚本执行步骤：

1. 检查本地 `docker`、`ssh` 命令可用
2. 验证 `propos-server` SSH 别名可连通
3. 在 `backend/` 目录执行 `docker build`，产物镜像：`ccr.ccs.tencentyun.com/ephnic/propos_backend:latest`
4. `docker push` 推送到腾讯云 TCR
5. SSH 到服务器：
   - `docker pull` 最新镜像
   - 停止并删除旧容器（不存在则跳过）
   - `docker run` 启动新容器（挂载 `/opt/propos/.env` + 数据卷）

### 4.2 验证

```bash
# 检查容器状态
ssh propos-server docker ps

# 通过 Nginx 检查 API 连通性（所有客户端统一入口，无需开放 8080）
curl http://111.230.112.246/api/health

# 若容器未接入 Nginx 或需直接验证（临时开放 8080 后执行）
# curl http://111.230.112.246:8080/api/health
```

### 4.3 查看后端日志

```bash
ssh propos-server docker logs -f propos-backend
```

---

## 五、Phase 2 — 部署前端（admin）

### 5.1 脚本说明

```bash
# 在项目根目录执行
bash admin/deploy.sh
```

脚本执行步骤：

1. 检查本地 `pnpm`、`rsync`、`ssh` 命令可用
2. 在 `admin/` 目录执行 `pnpm build`（`VITE_API_BASE_URL=''`，使 API 请求走相对路径，由 Nginx 反代处理）
3. `rsync` 增量同步 `admin/dist/` → 服务器 `/opt/propos/admin-dist/`
4. 同步 `admin/nginx.conf` → 服务器 `/opt/propos/nginx.conf`
5. SSH 到服务器：
   - 若 `propos-nginx` 容器不存在：执行 `docker run` 首次启动
   - 若容器已存在：执行 `docker restart propos-nginx`

### 5.2 Nginx 配置说明

`admin/nginx.conf` 关键配置：

- `/` → 托管 admin SPA 静态文件（支持 Vue Router history 模式）
- `/api/` → 反代到 `propos-backend:8080`（通过 Docker 网络 DNS 解析容器名）
- 启用 gzip 压缩（JS/CSS/JSON）

### 5.3 验证

```bash
# 浏览器访问
open http://111.230.112.246

# 检查 Nginx 日志
ssh propos-server docker logs -f propos-nginx
```

---

## 六、日常运维

### 新设备接入（多人协作部署）

脚本支持多台本地设备独立部署，各设备均可执行 `backend/deploy.sh` 和 `admin/deploy.sh`。新设备只需两步完成接入：

**Step 1 — 添加本机 SSH 公钥**

```bash
# 在新设备的项目根目录执行（服务器端各初始化步骤均已幂等保护，不会重复创建网络/容器/.env）
bash scripts/setup_server.sh
```

- 脚本会将新设备的 `~/.ssh/id_ed25519.pub` 追加到服务器 `authorized_keys`
- 服务器上 Docker 网络、PostgreSQL 容器、`.env` 已存在则**自动跳过**，不会覆盖生产配置
- TCR 登录步骤可直接按 Enter 跳过（服务器端凭据由首台设备配置一次即可）

**Step 2 — 确认 `.deploy.env` 凭据文件存在**

`.deploy.env` 是项目级凭据文件，每台设备各自维护（已 gitignore，不同步到版本控制）：

```bash
# 若新设备还没有该文件，从模板复制并填写
cp .deploy.env.example .deploy.env
```

编辑 `.deploy.env`，填写以下字段：

| 字段 | 是否必填 | 说明 |
|------|---------|------|
| `SERVER_SSH_PASSWORD` | 可选 | 服务器 root 密码，配合 `sshpass` 实现公钥推送全自动化；公钥推送成功后可清空 |
| `TCR_USER` | 必填 | 腾讯云账号 ID（`100004541753`） |
| `TCR_PASSWORD` | 必填 | TCR 访问凭证密码 |
| `SMTP_HOST` | 可选 | SMTP 服务器，本地与服务器统一配置 |
| `SMTP_PORT` | 可选 | 默认 465（隐式 SSL） |
| `SMTP_USER` | 可选 | SMTP 登录账号 |
| `SMTP_PASSWORD` | 可选 | SMTP 登录密码 |
| `SMTP_FROM` | 可选 | 发件人地址 |

完成后即可正常执行 `bash backend/deploy.sh` 和 `bash admin/deploy.sh`，无需手动 `docker login` 或输入服务器密码。

| 客户端类型 | API 访问路径 | 所需端口 |
|-----------|-------------|---------|
| admin（浏览器） | 相对路径 `/api/` → Nginx 反代 | 80 |
| Flutter App | `http://111.230.112.246/api/` | 80 |
| uni-app | `http://111.230.112.246/api/` | 80 |

> 三端 API 请求统一走 Nginx（端口 80），无需对外开放 8080。

---

### 查看所有容器状态

```bash
ssh propos-server docker ps -a
```

### 重启某个容器

```bash
ssh propos-server docker restart propos-backend
ssh propos-server docker restart propos-nginx
```

### 查看资源占用

```bash
ssh propos-server docker stats --no-stream
```

### 数据库备份

```bash
ssh propos-server "docker exec propos-postgres pg_dump -U propos propos | gzip > /opt/propos/backup-$(date +%Y%m%d).sql.gz"
```

### 更新环境变量

```bash
# 1. 编辑 .env
ssh propos-server vi /opt/propos/.env

# 2. 重新部署 backend 使配置生效
bash backend/deploy.sh
```

---

## 七、目录结构（服务器端）

```
/opt/propos/
  ├── .env                  # 生产环境变量（手动维护，不纳入版本控制）
  ├── nginx.conf            # Nginx 配置（由 admin/deploy.sh 同步）
  ├── admin-dist/           # admin 静态文件（由 admin/deploy.sh 同步）
  │   ├── index.html
  │   └── assets/
  └── backup-*.sql.gz       # 数据库备份（可选）

Docker 卷：
  propos-pgdata             # PostgreSQL 数据持久化
  propos-uploads            # 用户上传文件持久化
```

---

## 八、常见问题

### Q: docker push 失败，提示 unauthorized

```bash
docker login ccr.ccs.tencentyun.com
```

### Q: backend 容器启动后立即退出

```bash
# 查看错误日志
ssh propos-server docker logs propos-backend

# 常见原因：
# 1. /opt/propos/.env 中必填项未填写
# 2. DATABASE_URL 中容器名写错（应为 propos-postgres，不是 localhost）
# 3. ENCRYPTION_KEY 不足 64 个 hex 字符
```

### Q: admin 页面可以打开但 API 请求 404

```bash
# 检查 Nginx 配置是否生效
ssh propos-server docker exec propos-nginx nginx -t
ssh propos-server docker exec propos-nginx cat /etc/nginx/conf.d/default.conf

# 检查 backend 容器是否在 propos-net 网络中
ssh propos-server docker network inspect propos-net
```

### Q: 磁盘空间不足

```bash
# 清理悬空镜像和停止的容器
ssh propos-server docker system prune -f
```
