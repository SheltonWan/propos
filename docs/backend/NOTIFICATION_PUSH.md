# 实时通知与推送方案

> **文档版本**: v1.0
> **更新日期**: 2026-04-08
> **对应 PRD**: v1.7 §2.3 智能预警引擎

---

## 一、通知渠道矩阵

| 渠道 | 平台 | Phase 1 | 实时性 | 说明 |
|------|------|---------|--------|------|
| **系统内消息中心** | 全平台 | ✅ | 准实时（轮询） | 写入 `alerts` 表，前端定期拉取 |
| **邮件** | 全平台 | ✅ | 延迟（分钟级） | SMTP 发送，失败自动重试 |
| **FCM / uni-push 推送** | iOS / Android / HarmonyOS | ✅ | 实时 | uni-push 统一通道（集成 APNs/FCM/华为推送） |
| **应用内 Badge** | macOS / Windows / Web | ✅ | 准实时 | 未读数轮询，角标显示 |
| **企业微信 Webhook** | — | ❌ Phase 2 | 实时 | 预留接口 |
| **飞书 Webhook** | — | ❌ Phase 2 | 实时 | 预留接口 |

---

## 二、Phase 1 实现方案

### 2.1 整体流程

```
┌──────────────┐     ┌───────────────┐     ┌──────────────────┐
│  定时任务 /   │     │               │     │ 系统内消息中心    │
│  业务触发     │────▶│ NotifyService │────▶│ (alerts 表)      │
│              │     │               │     └──────────────────┘
└──────────────┘     │               │     ┌──────────────────┐
                     │               │────▶│ EmailService     │
                     │               │     │ (SMTP)           │
                     │               │     └──────────────────┘
                     │               │     ┌──────────────────┐
                     │               │────▶│ FCM Push         │
                     └───────────────┘     │ (iOS/Android)    │
                                           └──────────────────┘
```

### 2.2 轮询策略（桌面端 + Web）

| 参数 | 值 | 说明 |
|------|---|------|
| 轮询端点 | `GET /api/alerts/unread` | 返回 `{ data: { count: N } }` |
| 轮询间隔 | 30 秒 | 在 `ui_constants.ts` 定义 `ALERT_POLL_INTERVAL` |
| 应用前台 | 正常轮询 | 30 秒一次 |
| 应用后台 | 暂停轮询 | uni-app 通过 `onHide`/`onShow` 生命周期检测；Admin 通过 `visibilitychange` 事件检测 |
| 未读 > 0 | Badge 显示 | 导航栏铃铛图标 + 数字角标 |

### 2.3 uni-push 推送（移动端）

#### 后端集成

```dart
/// backend/lib/services/push_service.dart
class PushService {
  final String _pushAppId;     // 从环境变量 UNI_PUSH_APP_ID 读取
  final String _pushAppSecret; // 从环境变量 UNI_PUSH_APP_SECRET 读取

  /// 发送推送通知（通过 uni-push 服务端 API）
  Future<void> sendPush({
    required String clientId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // 调用 uni-push 服务端 REST API 发送推送
    // 支持 APNs(iOS) / 个推(Android) / 华为推送(HarmonyOS) 统一通道
  }
}
```

#### uni-app 端集成

```typescript
// app/src/utils/push.ts
import { onPushMessage } from '@dcloudio/uni-push'

// 获取 client id，上报给后端
uni.getPushClientId({
  success: async (res) => {
    await apiPost('/api/users/me/device-token', { token: res.cid })
  }
})

// 前台消息处理
onPushMessage((message) => {
  // 更新本地未读数 + 显示 Toast
})

// 点击通知消息导航
uni.onPushMessage((res) => {
  if (res.type === 'click') {
    // 根据 res.data.alert_id 导航到对应页面
    uni.navigateTo({ url: `/pages/alerts/detail?id=${res.data.alert_id}` })
  }
})
```

> **微信小程序**：不支持 uni-push，使用微信模板消息（订阅消息）替代，需单独申请模板。

#### 设备令牌管理

```sql
-- 新增表：user_device_tokens
CREATE TABLE user_device_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token TEXT         NOT NULL,
    platform     VARCHAR(20)  NOT NULL, -- 'ios', 'android', 'harmony', 'wechat_mp'
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, device_token)
);
```

---

## 三、NotifyService 实现

```dart
/// backend/lib/services/notify_service.dart
class NotifyService {
  final AlertRepository _alertRepo;
  final EmailService _emailService;
  final FcmService? _fcmService; // 可选，未配置 FCM_SERVER_KEY 时为 null
  final PushService? _pushService; // 可选，未配置 UNI_PUSH_APP_ID 时为 null

  /// 发送通知（多渠道分发）
  Future<void> notify({
    required String alertId,
    required String title,
    required String message,
    UUID? targetUserId,          // 指定用户；null 表示按角色广播
    List<String>? targetRoles,   // 广播角色列表
  }) async {
    final recipients = targetUserId != null
        ? [targetUserId]
        : await _userRepo.findByRoles(targetRoles!);

    final notifiedVia = <String>[];

    // 1. 系统内消息（始终写入）
    await _alertRepo.create(alertId: alertId, ...);
    notifiedVia.add('in_app');

    // 2. 邮件
    for (final uid in recipients) {
      final user = await _userRepo.findById(uid);
      if (user.email != null) {
        try {
          await _emailService.send(to: user.email!, subject: title, body: message);
          notifiedVia.add('email');
        } catch (e) {
          // 邮件失败记录日志，不阻塞
          await _logEmailFailure(alertId, uid, e);
        }
      }
    }

    // 3. uni-push 推送（仅移动端用户）
    if (_pushService != null) {
      final tokens = await _deviceTokenRepo.findActiveByUsers(recipients);
      for (final t in tokens) {
        try {
          await _pushService!.sendPush(
            clientId: t.deviceToken,
            title: title,
            body: message,
            data: {'alert_id': alertId},
          );
          if (!notifiedVia.contains('push')) notifiedVia.add('push');
        } catch (e) {
          await _logPushFailure(alertId, t.userId, e);
        }
      }
    }

    // 4. 更新 notified_via
    await _alertRepo.updateNotifiedVia(alertId, notifiedVia);
  }
}
```

---

## 四、预警接收角色映射

| 预警类型 | 目标角色 | 说明 |
|---------|---------|------|
| `lease_expiry_90/60/30` | `leasing_specialist`, `operations_manager` | 招商 + 运营经理 |
| `payment_overdue_1/7/15` | `finance_staff`, `leasing_specialist` | 财务 + 招商 |
| `monthly_expiry_summary` | `operations_manager`, `super_admin` | 管理层 |
| `deposit_refund_reminder` | `finance_staff` | 财务专员 |

---

## 五、防重复轰炸规则

| 规则 | 实现 |
|------|------|
| 同合同 + 同 alert_type + 同日 | `UNIQUE(contract_id, alert_type, DATE(triggered_at))` |
| 邮件发送失败重试 | 最多 3 次，间隔 30s / 60s / 120s |
| FCM 令牌失效 | 收到 `UNREGISTERED` 响应后标记 `is_active = false` |

---

## 六、环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `SMTP_HOST` | Phase 1 可选 | SMTP 服务器地址 |
| `SMTP_PORT` | Phase 1 可选 | SMTP 端口（默认 587） |
| `SMTP_USER` | Phase 1 可选 | SMTP 用户名 |
| `SMTP_PASSWORD` | Phase 1 可选 | SMTP 密码 |
| `SMTP_FROM` | Phase 1 可选 | 发件人地址 |
| `FCM_SERVER_KEY` | Phase 1 可选 | Firebase 服务端密钥（未配置则跳过 FCM 推送） |
| `UNI_PUSH_APP_ID` | Phase 1 可选 | uni-push 应用 ID（未配置则跳过 uni-push） |
| `UNI_PUSH_APP_SECRET` | Phase 1 可选 | uni-push 应用密钥 |

> **Phase 1 最小启动**：即使不配 SMTP/FCM，系统内消息中心 + 轮询轮询仍可正常工作，仅降级为"仅系统内通知"。
