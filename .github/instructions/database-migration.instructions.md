---
description: "Use when creating or modifying database migration files. Enforces TIMESTAMPTZ for timestamps, snake_case naming, encryption annotations, and safe migration practices."
applyTo: "backend/lib/**/migrations/**"
---

# 数据库迁移约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充迁移文件特有规则。

## 时间戳字段

全部使用 `TIMESTAMPTZ`（带时区），不得使用 `TIMESTAMP` 或 `TIMESTAMP WITHOUT TIME ZONE`：

```sql
-- ✅ 正确
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
start_date DATE NOT NULL,          -- 纯日期（无时间）用 DATE 类型

-- ❌ 禁止
created_at TIMESTAMP NOT NULL,
```

## 字段命名：snake_case

```sql
-- ✅ tenant_id, master_contract_id, is_leasable
-- ❌ tenantId, MasterContractId
```

## 加密字段注释（必须标注）

```sql
-- 证件号和手机号存储加密后的密文
id_number_encrypted  TEXT,         -- encrypted: AES-256
phone_encrypted      TEXT,         -- encrypted: AES-256
```

## 枚举类型

新增枚举使用 PostgreSQL `CREATE TYPE ... AS ENUM`，与 `data_model.md` 中已定义的类型保持一致，不重复定义。

参考 @file:docs/backend/data_model.md 中所有已定义的枚举类型清单。

## 安全迁移原则

| 操作 | 规则 |
|------|------|
| 删除列 | 先部署代码版本（不再使用该列）→ 再在下一版本 migration 中 DROP COLUMN |
| 重命名列 | 先 ADD COLUMN 新名 → 数据迁移 → 代码切换 → 再 DROP 旧列 |
| NOT NULL 约束 | 先 nullable 上线 → 补充数据 → 再加 NOT NULL |
| 大表索引 | 使用 `CREATE INDEX CONCURRENTLY`，避免锁表 |

## 迁移文件命名

```
V{版本号}__{描述}.sql
-- 示例：V20260408_01__create_buildings_table.sql
```

## 回滚脚本

每个迁移文件配套同名 `.undo.sql`（或在文件末尾添加 `DOWN` 注释块）：

```sql
-- DOWN (rollback)
DROP TABLE IF EXISTS buildings CASCADE;
```
