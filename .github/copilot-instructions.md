# Workspace Instructions

## Markdown 文档生成工作流

每当你（Copilot）生成 Markdown 文档，必须严格按以下流程执行，不得跳过：

### 步骤

1. **按模块保存 Markdown**：根据下方模块映射表，将 `.md` 文件写入对应子目录
2. **执行转换流水线**（在 workspace 根目录执行）：
   ```bash
   bash scripts/md_to_pdf.sh docs/<module>/<name>.md
   ```
   该脚本自动完成：`md → docx（中间文件）→ pdf`，并删除 `.docx`
3. **确认**：验证 `pdfdocs/<module>/<name>.pdf` 已生成，再向用户报告完成

### 模块 → 子目录映射

| 涉及模块 | Markdown 路径 | PDF 输出路径 |
|---------|--------------|-------------|
| backend（Dart 服务端） | `docs/backend/<name>.md` | `pdfdocs/backend/<name>.pdf` |
| frontend（Flutter 客户端） | `docs/frontend/<name>.md` | `pdfdocs/frontend/<name>.pdf` |
| 跨模块 / 通用 | `docs/<name>.md` | `pdfdocs/<name>.pdf` |

### 路径规范

| 类型 | 目录 |
|------|------|
| Markdown 源文件 | `docs/<module>/` 或 `docs/` |
| 中间 Word 文件 | 与 md 同目录（脚本自动删除） |
| 最终 PDF 输出 | `pdfdocs/<module>/`（自动镜像 docs 子目录结构） |

### 注意

- 不要手动调用 `md2word.py` 或 `docx2pdf.py`，统一使用 `scripts/md_to_pdf.sh`
- 如果 `pdfdocs/` 目录不存在，脚本会自动创建
- 批量生成时支持 `bash scripts/md_to_pdf.sh docs/<module>/*.md`

---

## PropOS 项目上下文

### 项目概述
PropOS（Property Operating System）是一套自有混合型物业的内部数字化资产运营管理平台。
管理约 40,000 m²、639 套房源，覆盖写字楼/商铺/公寓三业态。

### 技术栈
- **后端**: Dart（框架视具体选型，遵循 Repository + Service 分层架构）
- **移动端**: Flutter（iOS/Android 双端，主力工具）
- **Web 后台**: Flutter Web 或独立前端（PC 优先响应式设计）
- **微信小程序**: 精简版（仅扫码报修 + 状态查看）
- **数据库**: PostgreSQL（推荐）
- **文档**: Markdown → PDF（通过 scripts/md_to_pdf.sh）

### 核心领域模型

三业态枚举：
- `PropertyType`: `office`（写字楼）/ `retail`（商铺）/ `apartment`（公寓）

关键实体层级：
```
Building → Floor → Unit（资产层）
Tenant → Contract → Invoice（租务财务层）
Contract → SubLease（二房东穿透层）
WorkOrder（工单层）
```

核心计算公式：
- NOI = EGI - OpEx；EGI = PGI - VacancyLoss + OtherIncome
- WALE = Σ(剩余租期ᵢ × 年化租金ᵢ) / Σ(年化租金ᵢ)
- KPI总分 = Σ(指标得分ᵢ × 权重ᵢ)

### 代码规范
- Dart：遵循 Effective Dart，使用 `freezed` 生成不可变数据类
- 命名：`camelCase`（变量/函数）/ `PascalCase`（类型）/ `snake_case`（数据库列名）
- 每个业务模块目录结构：`models/ / repositories/ / services/ / controllers/（或 bloc/）`
- 测试：核心计算逻辑（WALE、NOI、KPI 打分）必须有单元测试
- 安全：租客证件号字段必须标注加密存储注释，API 响应默认脱敏

### Phase 1 模块边界
| 模块 | 状态 |
|------|------|
| M1 资产与空间可视化 | 含 CAD(.dwg→SVG/PNG) 转换 + 楼层热区状态色块 |
| M2 租务与合同管理 | 含状态机、WALE、租金递增规则配置器 |
| M3 财务与 NOI | 含自动账单生成、NOI 实时看板、KPI 仪表盘 |
| M4 工单系统 | 含 Flutter App 移动端 + 精简小程序 |
| M5 二房东穿透管理 | 含主从两级租赁、外部填报 Web 页、审核流 |

Phase 2 功能（租户门户、门禁、电子签章等）**不在当前开发范围内**，生成代码时不要超前实现。

### 架构约束
1. 所有 API 端点必须经过 RBAC 中间件验证角色权限
2. 二房东相关数据查询必须在 Repository 层加行级数据隔离过滤
3. 证件号、手机号字段在数据库层加密存储，API 层默认脱敏（仅显示后4位）
4. 操作审计日志覆盖：合同变更、账单核销、权限变更、二房东数据提交