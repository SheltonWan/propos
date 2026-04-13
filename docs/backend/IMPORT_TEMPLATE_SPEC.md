# PropOS Excel 导入模板字段规格

> **版本**: v1.0  
> **日期**: 2026-04-08  
> **依据**: PRD v1.8（六、数据初始化方案）/ data_model v1.4 / API_CONTRACT v1.7  
> **用途**: 定义 Excel 批量导入模板的列名、数据类型、校验规则与错误码映射  

---

## 一、导入概述

### 1.1 导入通道

| 数据类别 | 导入端点 | 数据类型标识 | 错误处理模式 |
|---------|---------|------------|------------|
| 单元台账（三业态分模板） | `POST /api/units/import` | `units` | **整批回滚** |
| 历史合同 | `POST /api/contracts/import` | `contracts` | **部分导入** |
| 未结账单 | `POST /api/invoices/import` | `invoices` | **部分导入** |
| 子租赁信息 | `POST /api/subleases/import` | `subleases` | **部分导入** |

### 1.2 通用规则

| 规则项 | 说明 |
|--------|------|
| 文件格式 | `.xlsx`（不接受 `.xls` / `.csv`） |
| 文件大小 | ≤ 10MB |
| 单次行数上限 | 1000 行（超过提示分批导入） |
| 首行 | **表头行**（列名必须与本文档定义完全一致，含中文） |
| 空行处理 | 跳过空行，不计入错误 |
| 试导入模式 | 请求参数 `dry_run=true` 时仅校验不入库 |
| 错误报告 | 返回 Excel 文件（原始行号 + 错误列 + 错误原因） |
| 批次追踪 | 每次导入生成 `import_batches` 记录，含 `batch_id`、操作人、时间、状态 |

### 1.3 通用列校验规则

| 校验类型 | 规则 |
|---------|------|
| 必填 | 标记为「必填」的列不可为空 |
| 枚举 | 必须匹配指定枚举值（中文或英文均可，系统映射） |
| 日期 | 格式 `YYYY-MM-DD`（Excel 日期格式自动识别） |
| 数字 | 正数，保留小数精度按字段定义 |
| 文本长度 | 不超过对应数据库字段 VARCHAR 长度 |
| 唯一性 | 文件内不可自重复 + 数据库中不可已存在 |

---

## 二、单元台账导入模板

### 2.1 写字楼单元模板

**文件名**: `单元台账_写字楼.xlsx`

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 楼栋名称 | → `buildings.name` | 文本 | 是 | 必须已存在于系统 | `BUILDING_NOT_FOUND` |
| B | 楼层名称 | → `floors.floor_name` | 文本 | 是 | 必须已存在于该楼栋 | `FLOOR_NOT_FOUND` |
| C | 单元编号 | `unit_number` | 文本(50) | 是 | 同楼栋内唯一 | `DUPLICATE_UNIT_NUMBER` |
| D | 建筑面积(m²) | `gross_area` | 数字(10,2) | 否 | > 0 | `INVALID_AREA` |
| E | 套内面积(m²) | `net_area` | 数字(10,2) | 是 | > 0，≤ 建筑面积 | `INVALID_AREA` |
| F | 朝向 | `orientation` | 枚举 | 否 | `东/南/西/北` → `east/south/west/north` | `INVALID_ENUM` |
| G | 层高(m) | `ceiling_height` | 数字(4,2) | 否 | > 0 | `INVALID_NUMBER` |
| H | 装修状态 | `decoration_status` | 枚举 | 是 | `毛坯/简装/精装/原始` → `blank/simple/refined/raw` | `INVALID_ENUM` |
| I | 是否可租 | `is_leasable` | 布尔 | 是 | `是/否` → `true/false` | `INVALID_BOOLEAN` |
| J | 参考市场租金(元/m²/月) | `market_rent_reference` | 数字(10,2) | 否 | ≥ 0 | `INVALID_NUMBER` |
| K | 工位数 | `ext_fields.workstation_count` | 整数 | 否 | ≥ 0 | `INVALID_NUMBER` |
| L | 分隔间数 | `ext_fields.partition_count` | 整数 | 否 | ≥ 0 | `INVALID_NUMBER` |

### 2.2 商铺单元模板

**文件名**: `单元台账_商铺.xlsx`

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 楼栋名称 | → `buildings.name` | 文本 | 是 | 必须已存在 | `BUILDING_NOT_FOUND` |
| B | 楼层名称 | → `floors.floor_name` | 文本 | 是 | 必须已存在 | `FLOOR_NOT_FOUND` |
| C | 单元编号 | `unit_number` | 文本(50) | 是 | 同楼栋内唯一 | `DUPLICATE_UNIT_NUMBER` |
| D | 建筑面积(m²) | `gross_area` | 数字(10,2) | 否 | > 0 | `INVALID_AREA` |
| E | 套内面积(m²) | `net_area` | 数字(10,2) | 是 | > 0 | `INVALID_AREA` |
| F | 朝向 | `orientation` | 枚举 | 否 | 同写字楼 | `INVALID_ENUM` |
| G | 层高(m) | `ceiling_height` | 数字(4,2) | 否 | > 0 | `INVALID_NUMBER` |
| H | 装修状态 | `decoration_status` | 枚举 | 是 | 同写字楼 | `INVALID_ENUM` |
| I | 是否可租 | `is_leasable` | 布尔 | 是 | `是/否` | `INVALID_BOOLEAN` |
| J | 参考市场租金(元/m²/月) | `market_rent_reference` | 数字(10,2) | 否 | ≥ 0 | `INVALID_NUMBER` |
| K | 门面宽度(m) | `ext_fields.frontage_width` | 数字(6,2) | 否 | > 0 | `INVALID_NUMBER` |
| L | 是否临街 | `ext_fields.street_facing` | 布尔 | 否 | `是/否` | `INVALID_BOOLEAN` |
| M | 商铺层高(m) | `ext_fields.retail_ceiling_height` | 数字(4,2) | 否 | > 0 | `INVALID_NUMBER` |

### 2.3 公寓单元模板

**文件名**: `单元台账_公寓.xlsx`

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 楼栋名称 | → `buildings.name` | 文本 | 是 | 必须已存在 | `BUILDING_NOT_FOUND` |
| B | 楼层名称 | → `floors.floor_name` | 文本 | 是 | 必须已存在 | `FLOOR_NOT_FOUND` |
| C | 单元编号 | `unit_number` | 文本(50) | 是 | 同楼栋内唯一 | `DUPLICATE_UNIT_NUMBER` |
| D | 建筑面积(m²) | `gross_area` | 数字(10,2) | 否 | > 0 | `INVALID_AREA` |
| E | 套内面积(m²) | `net_area` | 数字(10,2) | 是 | > 0 | `INVALID_AREA` |
| F | 朝向 | `orientation` | 枚举 | 否 | 同写字楼 | `INVALID_ENUM` |
| G | 层高(m) | `ceiling_height` | 数字(4,2) | 否 | > 0 | `INVALID_NUMBER` |
| H | 装修状态 | `decoration_status` | 枚举 | 是 | 同写字楼 | `INVALID_ENUM` |
| I | 是否可租 | `is_leasable` | 布尔 | 是 | `是/否` | `INVALID_BOOLEAN` |
| J | 参考市场租金(元/月) | `market_rent_reference` | 数字(10,2) | 否 | ≥ 0（注：公寓为整套月租） | `INVALID_NUMBER` |
| K | 卧室数 | `ext_fields.bedroom_count` | 整数 | 否 | ≥ 0 | `INVALID_NUMBER` |
| L | 独立卫生间 | `ext_fields.en_suite_bathroom` | 布尔 | 否 | `是/否` | `INVALID_BOOLEAN` |

---

## 三、历史合同导入模板

**文件名**: `历史合同导入.xlsx`

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 合同编号 | `contract_number` | 文本(100) | 是 | 全局唯一 | `DUPLICATE_CONTRACT_NUMBER` |
| B | 租客名称 | → `tenants.name` | 文本 | 是 | 必须已存在或自动创建 | `TENANT_NOT_FOUND` |
| C | 租客类型 | → `tenants.tenant_type` | 枚举 | 是 | `企业/个人` → `corporate/individual` | `INVALID_ENUM` |
| D | 证件号码 | → `tenants.id_number` | 文本 | 否 | 企业: 18位统一社会信用代码; 个人: 18位身份证 | `INVALID_ID_NUMBER` |
| E | 联系人 | → `tenants.contact_person` | 文本(100) | 是 | — | — |
| F | 联系电话 | → `tenants.contact_phone` | 文本(20) | 是 | 手机号格式 | `INVALID_PHONE` |
| G | 单元编号(多个用逗号分隔) | → `contract_units` | 文本 | 是 | 每个编号须在台账中存在 | `UNIT_NOT_FOUND` |
| H | 各单元计费面积(逗号分隔) | `contract_units.billing_area` | 数字列表 | 是 | 与 G 列一一对应，> 0 | `INVALID_AREA` |
| I | 各单元单价(逗号分隔) | `contract_units.unit_price` | 数字列表 | 是 | 与 G 列一一对应，> 0 | `INVALID_NUMBER` |
| J | 合同开始日期 | `start_date` | 日期 | 是 | `YYYY-MM-DD` | `INVALID_DATE` |
| K | 合同到期日期 | `end_date` | 日期 | 是 | > 开始日期 | `INVALID_DATE_RANGE` |
| L | 合同状态 | `status` | 枚举 | 是 | `执行中/已到期/已终止` → `active/expired/terminated` | `INVALID_ENUM` |
| M | 月租金(不含税) | 计算校验用 | 数字(12,2) | 是 | 应等于各单元(面积×单价)之和 | `RENT_MISMATCH` |
| N | 含税/不含税 | `tax_inclusive` | 枚举 | 是 | `含税/不含税` → `true/false` | `INVALID_ENUM` |
| O | 税率 | `tax_rate` | 数字(4,4) | 是 | 0.00 ~ 0.99 | `INVALID_TAX_RATE` |
| P | 付款周期(月) | `billing_cycle_months` | 整数 | 是 | 1/3/6/12 | `INVALID_BILLING_CYCLE` |
| Q | 押金月数 | → deposit | 整数 | 否 | ≥ 0 | `INVALID_NUMBER` |
| R | 押金金额 | → deposit | 数字(12,2) | 否 | ≥ 0 | `INVALID_NUMBER` |
| S | 免租开始日期 | `free_period_start` | 日期 | 否 | `YYYY-MM-DD` | `INVALID_DATE` |
| T | 免租结束日期 | `free_period_end` | 日期 | 否 | ≥ 免租开始日期 | `INVALID_DATE_RANGE` |

### 合同导入校验规则补充

| 规则项 | 说明 |
|--------|------|
| 合同编号判重 | 以 `contract_number` 判重，重复则阻止该行 |
| 租客自动匹配 | 优先按「租客名称 + 证件号」匹配；匹配不到则自动创建租客记录 |
| 多单元格式 | G/H/I 列逗号分隔值数量必须一致，否则报 `COLUMN_COUNT_MISMATCH` |
| 单元归属校验 | 每个单元不可已被其他 `active` 合同占用 | `UNIT_ALREADY_LEASED` |
| 状态联动 | 若导入状态为 `active`，合同到期日必须 ≥ 导入日期 |

---

## 四、未结账单导入模板

**文件名**: `未结账单导入.xlsx`

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 合同编号 | → `contracts.contract_number` | 文本 | 是 | 必须已存在 | `CONTRACT_NOT_FOUND` |
| B | 账期年月 | `billing_period` | 文本 | 是 | `YYYY-MM` 格式 | `INVALID_PERIOD` |
| C | 费项类型 | → `invoice_items.item_type` | 枚举 | 是 | `租金/物管费/电费/水费/停车费/储藏室/营业额分成/其他` | `INVALID_ENUM` |
| D | 金额(不含税) | `invoice_items.amount` | 数字(12,2) | 是 | > 0 | `INVALID_AMOUNT` |
| E | 税额 | `invoice_items.tax_amount` | 数字(12,2) | 否 | ≥ 0 | `INVALID_AMOUNT` |
| F | 账单状态 | `invoices.status` | 枚举 | 是 | `已出账/逾期` → `issued/overdue` | `INVALID_ENUM` |
| G | 应收日期 | `invoices.due_date` | 日期 | 是 | `YYYY-MM-DD` | `INVALID_DATE` |

### 账单导入校验规则补充

| 规则项 | 说明 |
|--------|------|
| 重复检测 | 同一合同 + 同一账期 + 同一费项类型不可重复 | `DUPLICATE_INVOICE_ITEM` |
| 合同状态 | 合同必须为 `active` 或 `expired`（不接受 `terminated`） | `INVALID_CONTRACT_STATUS` |
| 账期范围 | 账期必须在合同起止日期范围内 | `PERIOD_OUT_OF_RANGE` |

---

## 五、子租赁导入模板

**文件名**: `子租赁信息导入.xlsx`（内部 + 二房东外部通用）

| 列序 | 列名（表头） | 数据库字段 | 类型 | 必填 | 校验规则 | 错误码 |
|------|------------|-----------|------|------|---------|--------|
| A | 主合同编号 | → `contracts.contract_number` | 文本 | 是 | 必须存在且为二房东主合同 | `MASTER_CONTRACT_NOT_FOUND` |
| B | 单元编号 | → `units.unit_number` | 文本 | 是 | 必须在主合同覆盖范围内 | `UNIT_NOT_IN_SCOPE` |
| C | 终端租客名称 | `end_tenant_name` | 文本(200) | 是 | — | — |
| D | 租客类型 | `end_tenant_type` | 枚举 | 是 | `企业/个人` | `INVALID_ENUM` |
| E | 联系人 | `contact_person` | 文本(100) | 是 | — | — |
| F | 联系电话 | `contact_phone` | 文本(20) | 是 | 手机号格式 | `INVALID_PHONE` |
| G | 证件号码 | `id_number` | 文本 | 否 | 格式校验同合同导入 | `INVALID_ID_NUMBER` |
| H | 子租赁开始日期 | `start_date` | 日期 | 是 | `YYYY-MM-DD` | `INVALID_DATE` |
| I | 子租赁到期日期 | `end_date` | 日期 | 是 | > 开始日期 & ≤ 主合同到期日 | `SUBLEASE_EXCEEDS_MASTER` |
| J | 月租金 | `monthly_rent` | 数字(12,2) | 是 | > 0 | `INVALID_AMOUNT` |
| K | 入住状态 | `occupancy_status` | 枚举 | 是 | `已入住/已签约未入住/已退租/空置` | `INVALID_ENUM` |
| L | 入住人数 | `occupant_count` | 整数 | 否 | ≥ 0（仅公寓业态） | `INVALID_NUMBER` |
| M | 备注 | `notes` | 文本 | 否 | — | — |

### 子租赁导入校验规则补充

| 规则项 | 说明 |
|--------|------|
| 范围校验 | 单元必须在主合同关联的 `contract_units` 范围内 |
| 重复检测 | 同一单元不可同时存在多条 `占用中`（occupied / signed_not_moved）记录 | `DUPLICATE_ACTIVE_SUBLEASE` |
| 二房东外部导入 | 自动设置 `submitted_by_user_id` 为当前二房东用户，`review_status` 为 `pending` |
| 内部导入 | `review_status` 可由操作员指定，默认 `approved` |

---

## 六、导入错误报告格式

返回的错误 Excel 文件包含以下列：

| 列名 | 说明 |
|------|------|
| 原始行号 | 对应原始 Excel 的行号（含表头行，从 2 开始） |
| 错误列 | 出错的列名（如「单元编号」） |
| 错误码 | 系统错误码（如 `DUPLICATE_UNIT_NUMBER`） |
| 错误描述 | 人可读的中文描述（如 `单元编号"10A"在A座中已存在`） |
| 原始值 | 用户填入的原始内容 |

### 错误码汇总

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `BUILDING_NOT_FOUND` | 400 | 楼栋名称不存在 |
| `FLOOR_NOT_FOUND` | 400 | 楼层名称在指定楼栋中不存在 |
| `DUPLICATE_UNIT_NUMBER` | 409 | 单元编号已存在 |
| `UNIT_NOT_FOUND` | 400 | 单元编号在台账中不存在 |
| `UNIT_ALREADY_LEASED` | 409 | 单元已被其他有效合同占用 |
| `UNIT_NOT_IN_SCOPE` | 400 | 单元不在主合同覆盖范围内 |
| `DUPLICATE_CONTRACT_NUMBER` | 409 | 合同编号已存在 |
| `TENANT_NOT_FOUND` | 400 | 租客不存在且无法自动创建 |
| `CONTRACT_NOT_FOUND` | 400 | 合同编号不存在 |
| `MASTER_CONTRACT_NOT_FOUND` | 400 | 主合同不存在或非二房东合同 |
| `DUPLICATE_INVOICE_ITEM` | 409 | 账单重复 |
| `DUPLICATE_ACTIVE_SUBLEASE` | 409 | 同单元已有活跃子租赁 |
| `SUBLEASE_EXCEEDS_MASTER` | 400 | 子租赁到期日超出主合同到期日 |
| `INVALID_AREA` | 400 | 面积值无效 |
| `INVALID_NUMBER` | 400 | 数字格式或范围无效 |
| `INVALID_AMOUNT` | 400 | 金额无效 |
| `INVALID_ENUM` | 400 | 枚举值不在允许范围内 |
| `INVALID_DATE` | 400 | 日期格式错误 |
| `INVALID_DATE_RANGE` | 400 | 日期范围逻辑错误 |
| `INVALID_BOOLEAN` | 400 | 布尔值不是「是/否」 |
| `INVALID_PHONE` | 400 | 手机号格式错误 |
| `INVALID_ID_NUMBER` | 400 | 证件号码格式错误 |
| `INVALID_TAX_RATE` | 400 | 税率超出范围 |
| `INVALID_BILLING_CYCLE` | 400 | 付款周期不在允许值内 |
| `INVALID_CONTRACT_STATUS` | 400 | 合同状态不允许该操作 |
| `COLUMN_COUNT_MISMATCH` | 400 | 逗号分隔列数不一致 |
| `RENT_MISMATCH` | 400 | 月租金与各单元计算结果不符 |
| `PERIOD_OUT_OF_RANGE` | 400 | 账期不在合同有效期内 |

---

## 七、枚举值中英文映射表

供导入解析层使用的完整映射：

| 字段类型 | 中文值 | 英文枚举值 |
|---------|--------|-----------|
| 朝向 | 东 | east |
| 朝向 | 南 | south |
| 朝向 | 西 | west |
| 朝向 | 北 | north |
| 装修状态 | 毛坯 | blank |
| 装修状态 | 简装 | simple |
| 装修状态 | 精装 | refined |
| 装修状态 | 原始 | raw |
| 租客类型 | 企业 | corporate |
| 租客类型 | 个人 | individual |
| 合同状态 | 执行中 | active |
| 合同状态 | 已到期 | expired |
| 合同状态 | 已终止 | terminated |
| 账单状态 | 已出账 | issued |
| 账单状态 | 逾期 | overdue |
| 费项类型 | 租金 | rent |
| 费项类型 | 物管费 | management_fee |
| 费项类型 | 电费 | electricity |
| 费项类型 | 水费 | water |
| 费项类型 | 停车费 | parking |
| 费项类型 | 储藏室 | storage |
| 费项类型 | 营业额分成 | revenue_share |
| 费项类型 | 其他 | other |
| 入住状态 | 已入住 | occupied |
| 入住状态 | 已签约未入住 | signed_not_moved |
| 入住状态 | 已退租 | moved_out |
| 入住状态 | 空置 | vacant |
| 布尔值 | 是 | true |
| 布尔值 | 否 | false |
