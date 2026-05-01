# PropOS Admin

PropOS 物业运营管理平台 Web 后台，基于 Vue 3 + TypeScript + Element Plus 构建。

## 环境要求

- Node.js ≥ 18
- pnpm ≥ 9

## 安装依赖

```bash
pnpm install
```

## 启动方式

### 本地后端（默认）

后端服务运行在 `http://localhost:8080` 时直接启动：

```bash
pnpm dev
```

### 指定远程后端

**方式一：命令行传入（临时，不保存）**

```bash
VITE_API_BASE_URL=http://192.168.1.100:8080 pnpm dev
```

**方式二：本地配置文件（推荐，持久化）**

创建 `.env.remote.local`（已 gitignore，不会提交）：

```ini
VITE_API_BASE_URL=http://192.168.1.100:8080
```

然后启动：

```bash
pnpm dev:remote
```

> **原理**：开发模式下 axios 使用相对路径，所有 `/api/*` 请求由 Vite Dev Server 在服务端转发到 `VITE_API_BASE_URL`，浏览器不直接访问远程服务器，因此不受 CORS 限制。远程服务器只需确保网络可达（防火墙端口开放）即可。

## 构建

```bash
pnpm build
```

产物输出到 `dist/`，生产构建不读取 `.env.remote` / `.env.remote.local`，不受本地开发配置影响。

## 测试

```bash
# 单元测试（watch 模式）
pnpm test

# 单元测试（单次运行）
pnpm test:run

# 覆盖率报告
pnpm test:coverage

# E2E 测试（Mock 后端）
pnpm test:e2e

# E2E 测试（真实后端，需 .env.e2e 凭据）
pnpm test:e2e:real

# 查看 E2E 报告
pnpm test:e2e:report
```

E2E 真实后端测试需要在 `admin/` 目录创建 `.env.e2e`（参考 `.env.e2e.example`）。

## 环境变量说明

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `VITE_API_BASE_URL` | 后端 API 地址（仅控制 Vite proxy target） | `http://localhost:8080` |

## 目录结构

```
src/
  api/
    client.ts        # axios 封装（JWT 注入 + Token 刷新 + 错误统一转换）
    modules/         # 按领域拆分的 API 函数
  constants/         # 业务规则、UI、API 路径常量
  stores/            # Pinia stores（setup 风格）
  router/            # Vue Router 4 路由表与守卫
  views/             # 页面组件
  components/        # 共享组件
  types/             # TypeScript 接口定义
```
