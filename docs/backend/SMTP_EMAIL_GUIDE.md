# PropOS 邮件服务配置指南

**版本**：v1.0  
**适用范围**：后端 `EmailService` SMTP 配置，忘记密码 OTP 验证码发送场景  
**更新日期**：2026-04-21

---

## 一、概述

PropOS 后端通过 `EmailService`（`lib/shared/email_service.dart`）发送系统邮件，当前支持场景：

| 场景 | 触发接口 | 说明 |
|------|---------|------|
| 忘记密码 OTP 验证码 | `POST /api/auth/forgot-password` | 发送 6 位数字验证码，有效期 10 分钟 |

底层依赖 [mailer](https://pub.dev/packages/mailer) 包（v7.x）连接 SMTP 服务器。  
**若未配置 SMTP 主机，服务自动进入开发模式**：仅在控制台打印验证码，不实际发送邮件。

---

## 二、环境变量说明

所有 SMTP 配置通过 `.env` 文件（或系统环境变量）注入，**不得硬编码在代码中**。

| 变量名 | 是否必填 | 默认值 | 说明 |
|--------|---------|--------|------|
| `SMTP_HOST` | 否 | `""` | SMTP 服务器地址。**留空则进入开发模式** |
| `SMTP_PORT` | 否 | `465` | SMTP 端口。`465` = 隐式 SSL；`587` = STARTTLS |
| `SMTP_USER` | 否 | `""` | SMTP 认证用户名（通常为完整邮箱地址） |
| `SMTP_PASSWORD` | 否 | `""` | SMTP 认证密码 |
| `SMTP_FROM` | 否 | `noreply@propos.internal` | 发件人邮箱地址，需与 `SMTP_USER` 一致 |

> **安全注意**：`.env` 文件已加入 `.gitignore`，**严禁提交到版本控制**。生产环境通过 CI/CD 密钥管理注入。

---

## 三、腾讯企业邮箱配置（推荐）

PropOS 默认推荐使用腾讯企业邮箱（`exmail.qq.com`）。

### 3.1 前置步骤

1. 登录 [腾讯企业邮箱管理后台](https://exmail.qq.com)
2. 进入「设置」→「客户端协议」，确认 **SMTP 服务已开启**
3. 如果使用子账号发送，确保该账号具备邮件发送权限

### 3.2 `.env` 配置

```dotenv
SMTP_HOST=smtp.exmail.qq.com
SMTP_PORT=465
SMTP_USER=noreply@yourdomain.com
SMTP_PASSWORD=你的企业邮箱登录密码
SMTP_FROM=noreply@yourdomain.com
```

> 将 `yourdomain.com` 替换为实际企业域名（如 `smartwingtech.com`）。  
> 企业邮箱使用**账号登录密码**，无需生成授权码。

### 3.3 参数说明

| 参数 | 值 | 说明 |
|------|---|------|
| 主机 | `smtp.exmail.qq.com` | 腾讯企业邮箱专用 SMTP 地址 |
| 端口 | `465` | 隐式 SSL，代码自动启用 `ssl: true` |
| 认证 | 完整邮箱地址 + 登录密码 | 发件人地址须与认证账号一致 |

---

## 四、其他常见邮件服务商配置参考

### 4.1 QQ 个人邮箱

```dotenv
SMTP_HOST=smtp.qq.com
SMTP_PORT=465
SMTP_USER=your_qq@qq.com
SMTP_PASSWORD=16位授权码（非登录密码，在「设置→账户→POP3/SMTP」生成）
SMTP_FROM=your_qq@qq.com
```

### 4.2 网易 163 邮箱

```dotenv
SMTP_HOST=smtp.163.com
SMTP_PORT=465
SMTP_USER=your_account@163.com
SMTP_PASSWORD=授权码（在「设置→POP3/SMTP/IMAP」生成）
SMTP_FROM=your_account@163.com
```

### 4.3 Gmail（需开启两步验证 + 应用专用密码）

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_account@gmail.com
SMTP_PASSWORD=16位应用专用密码
SMTP_FROM=your_account@gmail.com
```

> Gmail 端口 `587` 使用 STARTTLS，代码自动对应 `ssl: false`。

### 4.4 阿里云企业邮箱

```dotenv
SMTP_HOST=smtp.mxhichina.com
SMTP_PORT=465
SMTP_USER=noreply@yourdomain.com
SMTP_PASSWORD=邮箱登录密码
SMTP_FROM=noreply@yourdomain.com
```

---

## 五、端口与加密方式

| 端口 | 加密方式 | `ssl` 参数 | 适用场景 |
|------|---------|-----------|---------|
| `465` | 隐式 SSL（SMTPS） | `true` | 腾讯企业邮、QQ、163 |
| `587` | STARTTLS | `false` | Gmail、部分国际服务商 |
| `25` | 无加密（不推荐） | `false` + `allowInsecure: true` | 仅内网测试，**生产禁用** |

代码自动根据端口判断：

```dart
final useSSL = _smtpPort == 465;
final smtpServer = SmtpServer(_smtpHost, port: _smtpPort, ssl: useSSL, ...);
```

---

## 六、开发模式行为

当 `SMTP_HOST` 为空（或未配置）时，服务进入**开发模式**，控制台输出如下信息，**不发送任何邮件**：

```
[EmailService] 开发模式：模拟发送 OTP 邮件
  收件人: user@example.com
  主题:   【PropOS】您的密码重置验证码
  验证码: 847291（有效期 10 分钟）
```

开发模式适用于本地调试，无需配置真实 SMTP 服务器。

---

## 七、验证配置

配置完成后，按以下步骤验证：

**1. 启动后端服务**

```bash
cd backend
dart run bin/server.dart
```

**2. 调用忘记密码接口**

```bash
curl -X POST http://localhost:8080/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "your_email@yourdomain.com"}'
```

**3. 预期结果**

- 接口返回 `200 OK`，响应体：`{"data": {"message": "如果该邮箱存在，验证码已发送"}}`
- 收件箱收到来自 `SMTP_FROM` 的验证码邮件
- 后端日志输出：`[EmailService] OTP 邮件已发送至 ...`

**常见错误排查：**

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `SmtpClientAuthenticationException` | 用户名或密码错误 | 检查 `SMTP_USER` / `SMTP_PASSWORD` |
| `SmtpClientCommunicationException` | 网络不通或端口被防火墙拦截 | 检查 `SMTP_HOST` / `SMTP_PORT`，确认端口开放 |
| `SmtpUnsecureException` | 服务器不支持 TLS | 改用端口 `465`（SSL） |
| 邮件进入垃圾箱 | 发件人域名未配置 SPF/DKIM | 联系邮箱服务商配置域名 DNS 记录 |

---

## 八、生产部署注意事项

1. **密钥管理**：生产环境 SMTP 密码通过 CI/CD 系统（如 GitHub Actions Secrets、K8s Secret）注入，不得写入代码或提交到 Git
2. **发件人域名**：`SMTP_FROM` 所用域名需在邮件服务商完成 SPF 和 DKIM 验证，否则邮件易被标记为垃圾邮件
3. **发送频率**：AuthService 已内置速率限制（同一账号 5 分钟内最多 3 次），无需在 SMTP 层额外限流
4. **监控**：建议在运维监控中跟踪 `[EmailService]` 日志关键字，及时发现发送失败情况
