# PropOS 认证接口 curl 测试指南

> **适用版本**: API v1.7  
> **前提**: 服务已启动（默认 `http://localhost:8080`）且种子数据已写入（`020_seed_reference_data.sql`）

---

## 一、测试账号速查

| 角色 | 邮箱 | 密码（seed 默认）| 说明 |
|------|------|-----------------|------|
| super_admin | `admin@propos.local` | `ChangeMe@2026!` | 首次登录后**必须**改密 |
| operations_manager | `chen.mgr@propos.local` | — | 需管理员先设置密码 |
| sub_landlord | `dingsheng@external.com` | — | 需管理员先设置密码 |

> 以下所有示例使用 `admin@propos.local` 演示。

---

## 二、环境变量准备（可选）

在 shell 中设置以下变量，避免每条命令重复写地址：

```bash
BASE_URL="http://localhost:8080"
```

---

## 三、登录 — `POST /api/auth/login`

### 3.1 正常登录

```bash
curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@propos.local",
    "password": "ChangeMe@2026!"
  }' | jq .
```

**期望响应（200）**

```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400,
    "user": {
      "id": "f0000000-0000-0000-0000-000000000001",
      "name": "系统管理员",
      "email": "admin@propos.local",
      "role": "super_admin",
      "department_id": null,
      "must_change_password": false
    }
  }
}
```

### 3.2 将 Token 保存到变量（方便后续请求使用）

```bash
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@propos.local","password":"ChangeMe@2026!"}')

ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')
REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.data.refresh_token')

echo "ACCESS_TOKEN=$ACCESS_TOKEN"
echo "REFRESH_TOKEN=$REFRESH_TOKEN"
```

### 3.3 错误场景：密码错误

```bash
curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@propos.local","password":"WrongPass"}' | jq .
```

**期望响应（401）**

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "用户名或密码错误"
  }
}
```

### 3.4 错误场景：账号锁定（连续失败达阈值）

**期望响应（423）**

```json
{
  "error": {
    "code": "ACCOUNT_LOCKED",
    "message": "账号已锁定",
    "locked_until": "2026-04-22T10:30:00Z"
  }
}
```

### 3.5 错误场景：账号停用

**期望响应（403）**

```json
{
  "error": {
    "code": "ACCOUNT_DISABLED",
    "message": "账号已停用"
  }
}
```

---

## 四、获取当前用户 — `GET /api/auth/me`

需在 `Authorization` Header 中携带 Access Token：

```bash
curl -s -X GET "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

**期望响应（200）**

```json
{
  "data": {
    "id": "f0000000-0000-0000-0000-000000000001",
    "name": "系统管理员",
    "email": "admin@propos.local",
    "role": "super_admin",
    "department_id": null,
    "department_name": null,
    "permissions": [
      "assets.read", "assets.write",
      "contracts.read", "contracts.write",
      "finance.read", "finance.write",
      "workorders.read", "workorders.write",
      "org.read", "org.manage"
    ],
    "bound_contract_id": null,
    "is_active": true,
    "last_login_at": "2026-04-22T08:00:00Z"
  }
}
```

**错误场景：Token 缺失或无效（401）**

```bash
curl -s -X GET "$BASE_URL/api/auth/me" | jq .
```

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "未登录或 Token 无效"
  }
}
```

---

## 五、刷新 Token — `POST /api/auth/refresh`

Access Token 过期后，使用 Refresh Token 换取新的令牌对：

```bash
curl -s -X POST "$BASE_URL/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}" | jq .
```

**期望响应（200）**

```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

> **注意**：Refresh Token 每次使用后轮换，旧 Refresh Token 立即失效。

**错误场景：Refresh Token 已过期（401）**

```json
{
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "Refresh Token 已过期"
  }
}
```

**错误场景：改密后旧 Token 失效（401）**

```json
{
  "error": {
    "code": "SESSION_VERSION_MISMATCH",
    "message": "会话已失效，请重新登录"
  }
}
```

---

## 六、修改密码 — `POST /api/auth/change-password`

成功后返回新 Token 对，旧 Token 立即失效：

```bash
curl -s -X POST "$BASE_URL/api/auth/change-password" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "old_password": "ChangeMe@2026!",
    "new_password": "NewSecure@2026!"
  }' | jq .
```

**期望响应（200）**

```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400
  }
}
```

**密码复杂度要求**：最少 8 位，必须含大小写字母 + 数字，不能与用户名相同。

**错误场景：旧密码错误（400）**

```json
{
  "error": {
    "code": "INVALID_OLD_PASSWORD",
    "message": "旧密码不正确"
  }
}
```

---

## 七、注销 — `POST /api/auth/logout`

吊销当前 Refresh Token：

```bash
curl -s -X POST "$BASE_URL/api/auth/logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}" | jq .
```

**期望响应（200）**

```json
{
  "data": {
    "message": "已注销"
  }
}
```

---

## 八、忘记密码（自助重置流程）

### 8.1 申请重置邮件 — `POST /api/auth/forgot-password`

```bash
curl -s -X POST "$BASE_URL/api/auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@propos.local"}' | jq .
```

**期望响应（200，无论邮箱是否存在均返回此响应，防枚举攻击）**

```json
{
  "data": {
    "message": "如该邮箱已注册，重置链接已发送"
  }
}
```

### 8.2 通过 Token 重置密码 — `POST /api/auth/reset-password`

```bash
curl -s -X POST "$BASE_URL/api/auth/reset-password" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<邮件中的重置 Token>",
    "new_password": "NewSecure@2026!"
  }' | jq .
```

**错误场景：Token 无效或已使用（400）**

```json
{
  "error": {
    "code": "OTP_INVALID",
    "message": "验证码不存在、已使用或输入错误"
  }
}
```

**错误场景：Token 已过期（400，有效期 10 分钟）**

```json
{
  "error": {
    "code": "OTP_EXPIRED",
    "message": "验证码已过期，请重新获取"
  }
}
```

> **注意**：二房东账号（`sub_landlord` 角色）不支持自助重置，需由管理员操作。

---

## 九、完整测试流程（一键脚本）

将以下内容保存为 `test_auth.sh`，在项目根目录执行：

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
EMAIL="admin@propos.local"
PASSWORD="ChangeMe@2026!"

echo "=== 1. 登录 ==="
RESP=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
echo "$RESP" | jq .

AT=$(echo "$RESP" | jq -r '.data.access_token')
RT=$(echo "$RESP" | jq -r '.data.refresh_token')

echo ""
echo "=== 2. 获取当前用户 ==="
curl -s "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $AT" | jq .

echo ""
echo "=== 3. 刷新 Token ==="
RESP2=$(curl -s -X POST "$BASE_URL/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AT" \
  -d "{\"refresh_token\":\"$RT\"}")
echo "$RESP2" | jq .

NEW_AT=$(echo "$RESP2" | jq -r '.data.access_token')
NEW_RT=$(echo "$RESP2" | jq -r '.data.refresh_token')

echo ""
echo "=== 4. 注销 ==="
curl -s -X POST "$BASE_URL/api/auth/logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $NEW_AT" \
  -d "{\"refresh_token\":\"$NEW_RT\"}" | jq .

echo ""
echo "=== 5. 注销后访问受保护接口（应返回 401）==="
curl -s "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $NEW_AT" | jq .

echo ""
echo "=== 测试完成 ==="
```

运行：

```bash
chmod +x test_auth.sh
./test_auth.sh
```

---

## 十、常见问题

| 问题 | 原因 | 解决方法 |
|------|------|---------|
| `Connection refused` | 服务未启动 | 在 `backend/` 目录执行 `dart run bin/server.dart` |
| `jq: command not found` | 未安装 jq | `brew install jq` |
| `INVALID_CREDENTIALS` | 密码错误或种子数据未导入 | 确认已执行 `020_seed_reference_data.sql` |
| `INTERNAL_ERROR` | 数据库未连接 | 检查 `.env` 中 `DATABASE_URL` 配置 |
| Token 立即过期 | `JWT_EXPIRES_IN_HOURS` 设置为 0 或负值 | 检查 `.env` 中 `JWT_EXPIRES_IN_HOURS` |
