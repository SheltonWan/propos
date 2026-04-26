# PropOS PostgreSQL 使用指南

> 版本: v1.0  
> 日期: 2026-04-09  
> 适用范围: PropOS 后端开发、本地联调、腾讯云测试/生产环境部署

---

## 1. 目标与范围

本文面向 PropOS 项目，提供一份可直接落地的 PostgreSQL 使用指南，覆盖以下场景：

1. 本地开发环境搭建
2. 腾讯云 PostgreSQL 环境搭建
3. PropOS 后端接入方式
4. 常用运维命令、备份策略与排障方法

本文基于当前仓库实际情况编写，重点说明以下约束：

- PropOS 后端要求 PostgreSQL 15+
- 后端通过环境变量 `DATABASE_URL` 连接数据库
- 当前后端连接池在 `backend/lib/config/database.dart` 中将 SSL 模式固定为 `disable`
- 当前仓库 `backend/migrations/` 目录只有 `.gitkeep`，尚未提供可直接执行的迁移入口
- 数据模型基线以 `docs/backend/data_model.md` 与 `docs/backend/MIGRATION_DRAFT_v1.7.md` 为准

---

## 2. PropOS 的 PostgreSQL 约束

### 2.1 版本与能力基线

PropOS 约定数据库为 PostgreSQL 15+，核心原因如下：

- 统一使用原生 SQL，不依赖 ORM
- 支持 `TIMESTAMPTZ`，满足 UTC 存储要求
- 支持 `JSONB`、GIN 索引、物化视图、丰富的聚合能力
- 便于后续扩展审计、分区、只读副本等能力

### 2.2 与当前代码相关的关键事实

后端会在启动时读取如下必须环境变量：

```bash
DATABASE_URL=postgres://用户名:密码@主机:端口/数据库名
JWT_SECRET=长度至少32位的随机字符串
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_PATH=/data/uploads
ENCRYPTION_KEY=64位十六进制字符串
APP_PORT=8080
```

当前数据库连接代码的行为是：

- 从 `DATABASE_URL` 解析主机、端口、数据库名、用户名、密码
- 初始化连接池时固定 `SslMode.disable`
- 启动时执行 `SELECT 1` 验证连通性

这意味着：

1. 本地环境可以直接使用明文 TCP 连接
2. 腾讯云环境优先使用同地域同 VPC 的内网连接
3. 如果未来要求公网强制 SSL，需要先调整后端连接池配置，再切换生产连接方式

### 2.3 数据建模约束

PropOS 数据库层需要遵守以下规则：

- 时间字段统一使用 `TIMESTAMPTZ`，按 UTC 存储
- 表名、列名统一使用 `snake_case`
- 证件号、手机号等敏感字段需要加密存储
- 分页遵循 `page`、`pageSize`、`total` 约定
- 二房东查询必须在 Repository 层做行级数据隔离过滤

---

## 3. 场景选择建议

| 场景 | 推荐方案 | 说明 |
| --- | --- | --- |
| 本地开发 | Homebrew 安装 PostgreSQL 15 | 最接近开发者日常使用方式，调试简单 |
| 本地隔离测试 | Docker 启动 PostgreSQL 15 | 适合快速重建环境、避免污染宿主机 |
| 腾讯云测试环境 | TencentDB for PostgreSQL | 便于验证内网接入、备份、监控 |
| 腾讯云生产环境 | TencentDB for PostgreSQL 高可用版 | 比 CVM 自建更稳，具备自动备份与高可用能力 |

不建议优先在腾讯云 CVM 上手工自建 PostgreSQL，除非你明确需要完全控制内核参数、扩展或存储路径，并愿意自行承担主从、高可用、备份、恢复和运维成本。

---

## 4. 本地搭建

## 4.1 方式 A: Homebrew 安装

适用于 macOS 开发机。

### 步骤 1: 安装 PostgreSQL 15

```bash
brew install postgresql@15
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

如果你使用 Intel Mac，请将路径中的 `/opt/homebrew` 改为 `/usr/local`。

### 步骤 2: 启动数据库服务

```bash
brew services start postgresql@15
brew services list | grep postgresql
```

### 步骤 3: 验证安装

```bash
psql --version
pg_isready
```

期望结果：

- `psql --version` 输出 15.x
- `pg_isready` 返回 accepting connections

### 步骤 4: 创建 PropOS 本地账号与数据库

```bash
psql postgres
```

进入 psql 后执行：

```sql
CREATE ROLE propos LOGIN PASSWORD 'ChangeMe_2026!';
CREATE DATABASE propos_dev OWNER propos ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE propos_dev TO propos;
```

退出：

```sql
\q
```

### 步骤 5: 验证连接

```bash
psql postgres://propos:ChangeMe_2026\!@localhost:5432/propos_dev -c "SELECT version();"
```

### 步骤 6: 连接 PropOS 后端

在 `backend/.env` 中配置：

```bash
DATABASE_URL=postgres://propos:ChangeMe_2026!@localhost:5432/propos_dev
JWT_SECRET=请替换为32位以上随机字符串
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_PATH=/data/uploads
ENCRYPTION_KEY=请替换为64位十六进制字符串
APP_PORT=8080
```

生成密钥示例：

```bash
openssl rand -base64 40
openssl rand -hex 32
```

---

## 4.2 方式 B: Docker 启动本地 PostgreSQL

适合你想快速重建数据库，或者不希望在宿主机长期安装 PostgreSQL 服务。

### 步骤 1: 拉起容器

```bash
docker run -d \
  --name propos-pg \
  -e POSTGRES_DB=propos_dev \
  -e POSTGRES_USER=propos \
  -e POSTGRES_PASSWORD=ChangeMe_2026! \
  -p 5432:5432 \
  -v propos_pg_data:/var/lib/postgresql/data \
  postgres:15
```

### 步骤 2: 检查容器状态

```bash
docker ps
docker logs propos-pg
```

### 步骤 3: 验证连接

```bash
psql postgres://propos:ChangeMe_2026!@localhost:5432/propos_dev -c "SELECT current_database();"
```

### 步骤 4: 停止与清理

```bash
docker stop propos-pg
docker start propos-pg
```

如需彻底删除容器与数据卷：

```bash
docker rm -f propos-pg
docker volume rm propos_pg_data
```

---

## 4.3 本地初始化建议

当前仓库尚未提交正式 SQL migration 文件，因此本地初始化建议按以下顺序进行：

1. 以 `docs/backend/data_model.md` 作为表结构基线
2. 以 `docs/backend/MIGRATION_DRAFT_v1.7.md` 作为迁移拆分顺序基线
3. 在 `backend/migrations/` 中补充形如 `001_init.sql`、`002_indexes.sql` 的正式脚本
4. 使用 `psql -f` 明确执行脚本，而不是手工在控制台粘贴大段 SQL

### 一键初始化脚本

仓库已提供本地初始化脚本：

```bash
bash scripts/init_local_postgres.sh
```

脚本默认行为：

1. 连接本地 PostgreSQL 管理库
2. 幂等创建 `propos` 角色与 `propos_dev` 数据库
3. 按顺序执行 `backend/migrations/*.sql`（如存在）
4. 不默认执行 `scripts/seed.sql`

常用用法：

```bash
# 只初始化角色和数据库，并尝试执行 migrations
bash scripts/init_local_postgres.sh

# 在 DDL 已准备完成后追加导入 seed 数据
bash scripts/init_local_postgres.sh --seed

# 只演练流程，不真正连接数据库
bash scripts/init_local_postgres.sh --dry-run --seed
```

如果本地 PostgreSQL 不是通过当前系统用户直接管理，而是需要明确指定管理员账号，可以使用标准 libpq 环境变量或 `ADMIN_DATABASE_URL`：

```bash
PGHOST=localhost \
PGPORT=5432 \
PGUSER=postgres \
PGPASSWORD=postgres \
bash scripts/init_local_postgres.sh
```

或者：

```bash
ADMIN_DATABASE_URL=postgres://postgres:postgres@localhost:5432/postgres \
bash scripts/init_local_postgres.sh
```

脚本支持的常用参数：

```bash
--db-name NAME
--db-user USER
--db-password PASS
--db-host HOST
--db-port PORT
--skip-migrations
--seed
--dry-run
```

推荐执行方式：

```bash
psql postgres://propos:ChangeMe_2026!@localhost:5432/propos_dev -f backend/migrations/001_init.sql
```

如果初始化脚本尚未落地，不要在文档、脚本或 CI 中假设 `dart run bin/migrate.dart` 可用，因为当前仓库不存在该入口。

---

## 5. 腾讯云搭建

## 5.1 推荐方案

腾讯云侧建议优先使用 **云数据库 TencentDB for PostgreSQL**，而不是 CVM 自建。原因如下：

- 控制台直接创建实例，省去手工安装与初始化
- 默认支持高可用架构
- 平台负责自动备份、增量日志备份、恢复能力
- 支持内网地址、外网地址、安全组、监控告警
- 更适合 PropOS 这类内部业务系统的长期运维

---

## 5.2 购买前规划

创建实例前先确定以下内容：

| 项目 | 建议 |
| --- | --- |
| 地域 | 与应用部署地域保持一致 |
| 网络 | 优先私有网络 VPC |
| 版本 | PostgreSQL 15 或更高 |
| 架构 | 高可用版 |
| 存储 | 从实际数据量与未来 12 个月增长预估反推 |
| 字符集 | UTF8 |
| 安全组 | 单独创建数据库专用安全组 |
| 连接方式 | 优先内网，公网仅用于短期运维 |

对 PropOS 来说，推荐部署组合是：

- 后端服务与 PostgreSQL 位于同一地域
- 后端服务与 PostgreSQL 位于同一 VPC
- 安全组仅放行业务服务器来源的 `TCP:5432`
- 尽量不启用公网访问

---

## 5.3 腾讯云创建实例步骤

根据腾讯云 PostgreSQL 官方文档，控制台创建实例时重点关注以下参数。

### 步骤 1: 进入购买页

登录腾讯云控制台，进入 PostgreSQL 购买页面，选择以下基础信息：

- 计费模式: 包年包月或按量计费
- 地域: 与业务计算资源一致
- 主可用区/备可用区: 建议跨可用区高可用
- 网络: 选择目标 VPC 和子网

### 步骤 2: 选择数据库配置

建议配置：

- 数据库大版本: 15+
- 架构: 高可用
- 实例规格: 按并发数、连接数、峰值查询量评估
- 硬盘: 至少覆盖当前数据量 + 备份增长 + 未来扩容空间
- 字符集: UTF8

### 步骤 3: 设置管理员账号

腾讯云对管理员用户名有约束：

- 不能使用 `postgres`
- 不能以 `pg_` 开头
- 不能以 `tencentdb_` 开头

建议使用：

```text
propos_admin
```

密码建议：

- 12 位以上
- 同时包含大小写字母、数字、特殊字符

### 步骤 4: 安全组与加密

创建时建议：

- 绑定数据库专用安全组
- 开启实例销毁保护
- 有合规要求时评估透明数据加密

### 步骤 5: 等待实例运行

购买完成后，在实例列表中等待状态变为“运行中”。

---

## 5.4 网络与访问控制

腾讯云文档确认了两个关键事实：

1. PostgreSQL 实例优先走私有网络 VPC 内网访问
2. 安全组放通数据库访问时，需要放行 `TCP:5432`

对 PropOS 的推荐做法如下。

### 推荐拓扑

```text
PropOS Backend -> 同地域 CVM / 容器 / 其他计算资源 -> VPC 内网 -> TencentDB for PostgreSQL
```

### 安全组规则建议

| 方向 | 来源 | 协议端口 | 策略 |
| --- | --- | --- | --- |
| 入站 | 应用服务器安全组 ID 或应用子网 CIDR | TCP:5432 | 允许 |

不建议直接配置：

```text
0.0.0.0/0 -> TCP:5432 -> Allow
```

这只适合临时排障，不适合正式环境。

### 是否启用公网地址

建议分场景处理：

- 开发/测试: 如必须从本地直连腾讯云数据库，可临时开启公网地址，并收紧来源 IP
- 生产: 优先只保留内网地址，不暴露公网入口

---

## 5.5 在腾讯云中创建 PropOS 数据库

实例创建完成后，登录数据库创建业务数据库。

### 使用 psql 连接

```bash
psql -U propos_admin -h <腾讯云内网地址或外网地址> -p 5432 -d postgres
```

### 创建业务数据库

```sql
CREATE DATABASE propos OWNER propos_admin ENCODING 'UTF8';
```

### 可选: 创建应用专用账号

如果你不希望应用直接使用管理员账号，可创建单独业务账号：

```sql
CREATE ROLE propos_app LOGIN PASSWORD 'ReplaceWithStrongPassword_2026!';
GRANT ALL PRIVILEGES ON DATABASE propos TO propos_app;
```

后续再按 schema 级别、表级别补细粒度授权。

---

## 5.6 PropOS 在腾讯云的连接方式

PropOS 当前代码通过 `DATABASE_URL` 建立连接，因此腾讯云环境的关键是把连接串配置正确。

### 推荐: 同 VPC 内网连接

```bash
DATABASE_URL=postgres://propos_app:ReplaceWithStrongPassword_2026!@10.x.x.x:5432/propos
```

优势：

- 网络延迟低
- 不暴露公网
- 与当前 `SslMode.disable` 的代码行为更匹配

### 临时: 本地或外部机器通过公网连接

```bash
DATABASE_URL=postgres://propos_app:ReplaceWithStrongPassword_2026!@<公网地址>:5432/propos
```

但要注意：

1. 需要先在腾讯云控制台开启公网地址
2. 需要限制来源 IP 或安全组范围
3. 当前 PropOS 代码未开启 SSL，公网长期使用风险较高

因此，正式环境不要把公网连接作为默认方案。

---

## 5.7 备份、恢复与监控

腾讯云官方文档给出的默认能力包括：

- 自动全量备份: 每天一次
- 增量日志备份: 约每 15 分钟或日志积累到阈值时触发
- 备份保留时间: 可配置 7 到 1830 天
- 支持手动备份与备份下载

对 PropOS 的建议如下：

### 备份策略建议

| 环境 | 自动备份保留期 | 手动备份 |
| --- | --- | --- |
| 开发 | 7 天 | 按需 |
| 测试 | 14 到 30 天 | 大版本变更前手动备份 |
| 生产 | 30 到 90 天 | 每次重大发布前手动备份 |

### 监控建议

至少关注以下指标：

- CPU 使用率
- 内存使用率
- 连接数
- 慢 SQL
- 存储容量使用率
- 备份任务状态

### 发布前建议动作

1. 执行一次手动备份
2. 校验最近一次自动备份成功
3. 检查连接数是否接近规格上限
4. 检查慢 SQL 是否持续堆积

---

## 6. PropOS 接入与初始化示例

## 6.1 本地 `.env` 示例

```bash
DATABASE_URL=postgres://propos:ChangeMe_2026!@localhost:5432/propos_dev
JWT_SECRET=replace-with-at-least-32-chars-random-secret
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_PATH=/data/uploads
ENCRYPTION_KEY=replace-with-64-hex-characters
APP_PORT=8080
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
LOG_LEVEL=info
MAX_UPLOAD_SIZE_MB=50
```

## 6.2 腾讯云 `.env` 示例

```bash
DATABASE_URL=postgres://propos_app:ReplaceWithStrongPassword_2026!@10.0.0.12:5432/propos
JWT_SECRET=replace-with-at-least-32-chars-random-secret
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_PATH=/data/uploads
ENCRYPTION_KEY=replace-with-64-hex-characters
APP_PORT=8080
CORS_ORIGINS=https://propos.example.com
LOG_LEVEL=info
MAX_UPLOAD_SIZE_MB=50
```

## 6.3 启动前检查

在启动后端前，至少执行以下检查：

```bash
psql "$DATABASE_URL" -c "SELECT current_database(), now();"
```

如果这条命令不通，不要先启动后端。应先检查网络、账号密码、数据库名和安全组。

---

## 7. 常用 SQL 与运维命令

## 7.1 查看数据库与角色

```bash
psql "$DATABASE_URL" -c "\l"
psql "$DATABASE_URL" -c "\du"
```

## 7.2 查看当前连接

```bash
psql "$DATABASE_URL" -c "SELECT pid, usename, client_addr, state, query FROM pg_stat_activity ORDER BY backend_start DESC;"
```

## 7.3 查看数据库大小

```bash
psql "$DATABASE_URL" -c "SELECT pg_size_pretty(pg_database_size(current_database()));"
```

## 7.4 导出备份

```bash
pg_dump "$DATABASE_URL" -Fc -f propos_$(date +%Y%m%d_%H%M%S).dump
```

## 7.5 恢复备份

```bash
createdb -h localhost -p 5432 -U propos propos_restore
pg_restore -d postgres://propos:ChangeMe_2026!@localhost:5432/propos_restore propos_20260409_120000.dump
```

## 7.6 执行初始化脚本

```bash
psql "$DATABASE_URL" -f backend/migrations/001_init.sql
```

## 7.7 本地测试：检查数据是否正确写入

### 查看某张表最新 N 条记录

PropOS 所有表均有 `created_at TIMESTAMPTZ` 字段，按此字段倒序即可查看最新写入的数据：

```sql
-- 以 contracts 表为例，查看最新 10 条
SELECT * FROM contracts ORDER BY created_at DESC LIMIT 10;

-- 其他常用表
SELECT * FROM buildings   ORDER BY created_at DESC LIMIT 10;
SELECT * FROM units       ORDER BY created_at DESC LIMIT 10;
SELECT * FROM tenants     ORDER BY created_at DESC LIMIT 10;
SELECT * FROM invoices    ORDER BY created_at DESC LIMIT 10;
SELECT * FROM work_orders ORDER BY created_at DESC LIMIT 10;
```

### 统计各表行数（快速确认批量写入结果）

```sql
SELECT
  schemaname,
  relname        AS table_name,
  n_live_tup     AS row_count
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

> 注意：`n_live_tup` 是近似值，刚写入后短暂延迟才会更新。精确行数用 `SELECT COUNT(*) FROM <table>`。

### 验证最后一次 API 写入

在后端 API 完成一次 POST/PATCH 请求后，立即用 `id` 或时间戳确认记录：

```bash
# 命令行一行查最新一条，适合快速验证
psql "$DATABASE_URL" -c "SELECT id, status, created_at FROM contracts ORDER BY created_at DESC LIMIT 1;"
```

### 检查加密字段是否已加密存储

证件号、手机号等敏感字段在数据库中应为密文，不应出现明文值：

```sql
-- 确认字段值不是原始明文（正确：应为一段不可读密文）
SELECT id, id_number FROM tenants LIMIT 5;
```

如果查询结果中 `id_number` 显示为可读字符串，说明加密未生效，需排查 `backend/lib/shared/encryption.dart`。

### 查看表结构

确认字段类型与迁移脚本一致：

```bash
psql "$DATABASE_URL" -c "\d contracts"
psql "$DATABASE_URL" -c "\d+ units"
```

---

## 8. 常见问题

## 8.1 `connection refused`

优先检查：

- PostgreSQL 服务是否启动
- 端口是否为 `5432`
- Docker 容器是否映射端口
- 腾讯云安全组是否已放通 `TCP:5432`

## 8.2 `password authentication failed`

优先检查：

- `DATABASE_URL` 中的用户名或密码是否错误
- 腾讯云实例使用的是不是初始化管理员账号
- 是否误连到了错误实例或错误数据库

## 8.3 后端启动时报数据库错误

PropOS 启动时会立即校验数据库连接。如果连接失败，优先检查：

1. `DATABASE_URL` 是否存在
2. 数据库主机、端口、数据库名是否正确
3. 数据库网络是否可达
4. 账号是否具备连接目标数据库的权限

## 8.4 腾讯云公网能连，内网不能连

优先检查：

- 应用与数据库是否在同一地域
- 是否在同一 VPC
- 是否需要对等连接或网络变更
- 安全组是否只放开了公网来源，没放开业务子网来源

## 8.5 腾讯云要求 SSL，但当前服务端没配

当前仓库 `backend/lib/config/database.dart` 中固定为 `SslMode.disable`。如果你所在环境明确要求 SSL：

1. 先改造后端连接池配置，使其支持 `SslMode.require` 或更严格模式
2. 再切换连接地址与证书配置
3. 在测试环境完成验证后再进入生产

在代码未调整前，不要在文档和部署脚本里假设服务端已经支持 SSL。

---

## 9. 落地检查清单

### 本地开发环境

- PostgreSQL 版本为 15+
- 本地数据库 `propos_dev` 已创建
- `DATABASE_URL` 可被 `psql` 成功连接
- `backend/.env` 已补齐全部必须变量
- 初始化 SQL 已通过 `psql -f` 执行

### 腾讯云环境

- 实例版本为 PostgreSQL 15+
- 应用与数据库同地域部署
- 优先使用 VPC 内网连接
- 安全组仅允许业务来源访问 `TCP:5432`
- 自动备份与监控告警已启用
- 发布前已完成手动备份

---

## 10. 相关文档

- `docs/DEV_ENV_SETUP.md`
- `docs/DEPLOYMENT.md`
- `docs/backend/data_model.md`
- `docs/backend/MIGRATION_DRAFT_v1.7.md`

如果后续需要把这份指南升级为“可执行初始化手册”，下一步应补齐以下产物：

1. `backend/migrations/001_init.sql` 等正式迁移脚本
2. 数据库初始化任务或统一执行脚本
3. 腾讯云测试环境实际连接参数模板
---

## 附录：psql 常用查询命令速查

### 元命令（psql 内置）

| 命令 | 作用 |
|------|------|
| `\l` | 列出所有数据库 |
| `\c propos_dev` | 切换到指定数据库 |
| `\dt` | 列出当前 schema 的所有表 |
| `\dt *.*` | 列出所有 schema 的表 |
| `\d tablename` | 查看表结构（列、类型、约束） |
| `\d+ tablename` | 查看表结构（含注释、存储参数） |
| `\di` | 列出所有索引 |
| `\dv` | 列出所有视图 |
| `\dn` | 列出所有 schema |
| `\du` | 列出所有角色/用户 |
| `\dp tablename` | 查看表的权限 |
| `\timing` | 切换显示查询耗时 |
| `\x` | 切换扩展模式（竖向展示行） |

### 常用 SQL 查询

```sql
-- 查询行数
SELECT COUNT(*) FROM tablename;

-- 查看所有表（系统视图）
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- 查看表结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'tablename';

-- 查看表大小
SELECT pg_size_pretty(pg_total_relation_size('tablename'));

-- 查看所有 migration 记录（本项目专用）
SELECT * FROM schema_migrations ORDER BY applied_at;

-- 查看角色
SELECT rolname, rollogin FROM pg_roles;

-- 查看当前连接信息
SELECT current_database(), current_user, version();
```

### 快速连接本项目数据库

```bash
# 以 propos 角色连接业务库
PGPASSWORD=ChangeMe_2026! psql -h localhost -p 5432 -U propos -d propos_dev
```4. SSL 模式可配置化改造