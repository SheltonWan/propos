# PropOS 种子数据业务样本规格

> **版本**: v1.1  
> **日期**: 2026-04-09  
> **依据**: PRD v1.7 / data_model v1.3 / API_CONTRACT v1.7  
> **用途**: 为开发自测、单元测试、集成测试与 WALE/NOI/KPI 验算提供标准化参考数据  

---

## 一、楼栋与楼层种子

| building_id (简称) | name | property_type | total_floors | gfa (m²) | nla (m²) |
|-------------------|------|---------------|-------------|----------|----------|
| B-OFFICE | A座 | office | 20 | 30000.00 | 25500.00 |
| B-RETAIL | 商铺区 | retail | 2 | 2707.00 | 2300.00 |
| B-APT | 公寓楼 | apartment | 8 | 7300.00 | 6200.00 |

### 楼层样本（含三栋楼 + SVG 路径字段）

> `floor_plan_svg_path` 由 CAD 转换工具写入，格式 `floors/{building_uuid}/{floor_uuid}.svg`，下表以符号名代替 UUID，实际 seed.sql 中路径在写入文件后 UPDATE 对应行。

#### A 座楼层

| building | floor_number | floor_name | nla (m²) | floor_plan_svg_path |
|----------|-------------|------------|----------|---------------------|
| B-OFFICE | -1 | B1 | 0.00 | null（设备层，无图纸）|
| B-OFFICE | 1 | 1F | 1200.00 | floors/B-OFFICE/1F.svg |
| B-OFFICE | 2 | 2F | 1350.00 | floors/B-OFFICE/2F.svg |
| B-OFFICE | 10 | 10F | 1350.00 | floors/B-OFFICE/10F.svg |
| B-OFFICE | 20 | 20F | 1200.00 | floors/B-OFFICE/20F.svg |

#### 商铺区楼层

| building | floor_number | floor_name | nla (m²) | floor_plan_svg_path |
|----------|-------------|------------|----------|---------------------|
| B-RETAIL | 1 | 1F | 1150.00 | floors/B-RETAIL/1F.svg |
| B-RETAIL | 2 | 2F | 1150.00 | floors/B-RETAIL/2F.svg |

#### 公寓楼楼层

| building | floor_number | floor_name | nla (m²) | floor_plan_svg_path |
|----------|-------------|------------|----------|---------------------|
| B-APT | 1 | 1F | 750.00 | null（机房/管理室，无平面图）|
| B-APT | 3 | 3F | 780.00 | floors/B-APT/3F.svg |
| B-APT | 5 | 5F | 780.00 | floors/B-APT/5F.svg |
| B-APT | 8 | 8F | 750.00 | floors/B-APT/8F.svg |

---

## 二、单元种子（每业态各 5 条典型样本）

### 2.1 写字楼单元

| unit_number | floor | gross_area | net_area | orientation | ceiling_height | decoration_status | is_leasable | market_rent_reference | ext_fields |
|-------------|-------|-----------|----------|-------------|---------------|-------------------|------------|----------------------|------------|
| 10A | 10F | 320.00 | 280.00 | south | 3.00 | refined | true | 120.00 | `{"workstation_count": 40, "partition_count": 5}` |
| 10B | 10F | 160.00 | 140.00 | east | 3.00 | simple | true | 110.00 | `{"workstation_count": 18, "partition_count": 2}` |
| 10C | 10F | 85.00 | 72.00 | north | 3.00 | blank | true | 95.00 | `{"workstation_count": 8, "partition_count": 1}` |
| 20A | 20F | 500.00 | 440.00 | south | 3.00 | refined | true | 135.00 | `{"workstation_count": 60, "partition_count": 8}` |
| 1-LOBBY | 1F | 200.00 | null | null | 5.50 | refined | false | null | `{}` |

### 2.2 商铺单元

| unit_number | floor | gross_area | net_area | orientation | ceiling_height | decoration_status | is_leasable | market_rent_reference | ext_fields |
|-------------|-------|-----------|----------|-------------|---------------|-------------------|------------|----------------------|------------|
| S101 | 1F | 120.00 | 108.00 | south | 5.20 | refined | true | 250.00 | `{"frontage_width": 8.5, "street_facing": true, "retail_ceiling_height": 5.2}` |
| S102 | 1F | 80.00 | 72.00 | south | 4.50 | simple | true | 200.00 | `{"frontage_width": 6.0, "street_facing": true, "retail_ceiling_height": 4.5}` |
| S103 | 1F | 200.00 | 180.00 | south | 5.20 | blank | true | 280.00 | `{"frontage_width": 12.0, "street_facing": true, "retail_ceiling_height": 5.2}` |
| S201 | 2F | 150.00 | 135.00 | east | 4.00 | simple | true | 150.00 | `{"frontage_width": 0, "street_facing": false, "retail_ceiling_height": 4.0}` |
| S-COMMON | 1F | 50.00 | null | null | 5.20 | refined | false | null | `{}` |

### 2.3 公寓单元

| unit_number | floor | gross_area | net_area | orientation | ceiling_height | decoration_status | is_leasable | market_rent_reference | ext_fields |
|-------------|-------|-----------|----------|-------------|---------------|-------------------|------------|----------------------|------------|
| A301 | 3F | 45.00 | 38.00 | south | 2.80 | refined | true | 3500.00 | `{"bedroom_count": 1, "en_suite_bathroom": true, "occupant_count": null}` |
| A302 | 3F | 65.00 | 55.00 | south | 2.80 | refined | true | 5200.00 | `{"bedroom_count": 2, "en_suite_bathroom": true, "occupant_count": null}` |
| A303 | 3F | 35.00 | 28.00 | north | 2.80 | simple | true | 2800.00 | `{"bedroom_count": 1, "en_suite_bathroom": false, "occupant_count": null}` |
| A501 | 5F | 90.00 | 78.00 | south | 2.80 | refined | true | 7500.00 | `{"bedroom_count": 3, "en_suite_bathroom": true, "occupant_count": null}` |
| A-ELEC | 1F | 15.00 | null | null | 2.80 | raw | false | null | `{}` |

> **market_rent_reference 说明**: 写字楼/商铺为 元/m²/月，公寓为 整套月租金（元/月）。

---

## 三、租客种子

| tenant_id (简称) | name | tenant_type | id_number (加密前原文) | contact_person | contact_phone | credit_rating |
|------------------|------|------------|----------------------|----------------|--------------|---------------|
| T-CORP-A | 明辉科技有限公司 | corporate | 91440300MA5FKJ1234 | 王经理 | 13800001111 | A |
| T-CORP-B | 百恒传媒有限公司 | corporate | 91440300MA5GHK5678 | 李总 | 13900002222 | B |
| T-CORP-C | 聚鑫餐饮连锁有限公司 | corporate | 91440300MA5JLN9012 | 陈店长 | 13700003333 | A |
| T-IND-D | 张三 | individual | 440305199001011234 | 张三 | 13600004444 | B |
| T-SUBLORD | 鼎盛物业管理有限公司 | corporate | 91440300MA5ABC3456 | 赵总 | 13500005555 | A |

> **脱敏提示**: `id_number` 在数据库中 AES-256 加密存储；API 默认返回 `****1234` 格式。

---

## 四、合同种子（覆盖三业态 + 混合递增 + 多单元 + 二房东）

### 4.1 写字楼标准合同

| 字段 | 值 |
|------|---|
| contract_id | C-OFFICE-01 |
| tenant | T-CORP-A（明辉科技） |
| contract_number | HT-2025-OFFICE-001 |
| status | active |
| start_date | 2025-06-01 |
| end_date | 2028-05-31 |
| billing_cycle_months | 3（季付） |
| tax_inclusive | false |
| tax_rate | 0.09 |
| free_period_start | 2025-06-01 |
| free_period_end | 2025-06-14 |
| **关联单元** | 10A（计费面积 280m²，单价 ¥110/m²/月）+ 10B（计费面积 140m²，单价 ¥105/m²/月） |
| **月租金** | 280×110 + 140×105 = 30,800 + 14,700 = **¥45,500/月**（不含税） |
| **含税月租** | 45,500 × 1.09 = **¥49,595/月** |
| 物管费 | ¥15/m²/月（共 420m²）= ¥6,300/月 |
| deposit_months | 3 |
| deposit_amount | 45,500 × 3 = **¥136,500** |

**递增规则（混合分段）**：

| 阶段 | 区间 | 类型 | 参数 | 生效单价(10A) | 生效单价(10B) |
|------|------|------|------|-------------|-------------|
| 1 | 2025-06 ~ 2027-05 | 固定租金（免租后基准） | 基准价 | ¥110 | ¥105 |
| 2 | 2027-06 ~ 2028-05 | 固定比例递增 | +5% | ¥115.50 | ¥110.25 |

**验算用月租金时间线**：

| 月份 | 10A 月租 | 10B 月租 | 合计 | 备注 |
|------|---------|---------|------|------|
| 2025-06（前14天免租） | ¥16,426.67 | ¥7,840.00 | ¥24,266.67 | 按 16/30 折算（计费16天，30,800×16/30，14,700×16/30）|
| 2025-07 ~ 2027-05 | ¥30,800 | ¥14,700 | ¥45,500 | 基准 |
| 2027-06 ~ 2028-05 | ¥32,340 | ¥15,435 | ¥47,775 | +5% |

### 4.2 商铺保底+营业额分成合同

| 字段 | 值 |
|------|---|
| contract_id | C-RETAIL-01 |
| tenant | T-CORP-C（聚鑫餐饮） |
| contract_number | HT-2025-RETAIL-001 |
| status | active |
| start_date | 2025-03-01 |
| end_date | 2028-02-28 |
| billing_cycle_months | 1（月付） |
| tax_inclusive | false |
| tax_rate | 0.05（简易征收） |
| free_period_start | 2025-03-01 |
| free_period_end | 2025-05-31 |
| **关联单元** | S101（计费面积 108m²，单价 ¥230/m²/月） |
| **保底月租** | 108 × 230 = **¥24,840/月**（不含税） |
| **营业额分成比例** | 8% |
| deposit_months | 6 |
| deposit_amount | 24,840 × 6 = **¥149,040** |

**营业额分成计算示例**：

| 月份 | 月营业额 | 8%分成额 | 保底租金 | 应收取 | 计算逻辑 |
|------|---------|---------|---------|-------|---------|
| 2025-06 | ¥250,000 | ¥20,000 | ¥24,840 | **¥24,840** | MAX(24840, 20000) = 保底 |
| 2025-07 | ¥350,000 | ¥28,000 | ¥24,840 | **¥28,000** | MAX(24840, 28000) = 分成 |
| 2025-08 | ¥310,000 | ¥24,800 | ¥24,840 | **¥24,840** | MAX(24840, 24800) ≈ 保底（边界） |
| 2025-09 | ¥500,000 | ¥40,000 | ¥24,840 | **¥40,000** | MAX(24840, 40000) = 分成 |

> **含税处理**: 应收取金额为不含税口径；含税账单 = 应收 × (1+5%) 。NOI 计算使用不含税金额。

**递增规则（阶梯式）**：

| 阶段 | 区间 | 类型 | 保底单价 |
|------|------|------|---------|
| 1 | 2025-03 ~ 2026-02 | 阶梯式 | ¥230/m² |
| 2 | 2026-03 ~ 2027-02 | 阶梯式 | ¥250/m² |
| 3 | 2027-03 ~ 2028-02 | 阶梯式 | ¥270/m² |

### 4.3 公寓短租合同

| 字段 | 值 |
|------|---|
| contract_id | C-APT-01 |
| tenant | T-IND-D（张三） |
| contract_number | HT-2025-APT-001 |
| status | active |
| start_date | 2025-07-01 |
| end_date | 2026-06-30 |
| billing_cycle_months | 1（月付） |
| tax_inclusive | true |
| tax_rate | 0.05 |
| **关联单元** | A302（整套月租 ¥5,000/月，含税） |
| **不含税月租** | 5,000 / 1.05 = **¥4,761.90** |
| 物管费 | 含于租金 |
| deposit_months | 2 |
| deposit_amount | 5,000 × 2 = **¥10,000** |

**递增规则**: 无（1年短租不设递增）。

### 4.4 二房东整租合同

| 字段 | 值 |
|------|---|
| contract_id | C-SUB-MASTER |
| tenant | T-SUBLORD（鼎盛物业） |
| contract_number | HT-2024-OFFICE-SUB-001 |
| status | active |
| start_date | 2024-01-01 |
| end_date | 2029-12-31 |
| billing_cycle_months | 3（季付） |
| tax_inclusive | false |
| tax_rate | 0.09 |
| **关联单元** | 20A（计费面积 440m²，单价 ¥95/m²/月） |
| **月租金** | 440 × 95 = **¥41,800/月** |
| deposit_months | 6 |
| deposit_amount | 41,800 × 6 = **¥250,800** |

**递增规则（每2年递增）**：

| 阶段 | 区间 | 类型 | 参数 |
|------|------|------|------|
| 1 | 2024-01 ~ 2025-12 | 固定租金 | 基准 ¥95/m² |
| 2 | 2026-01 ~ 2027-12 | 每N年递增 | +8%，单价 ¥102.60/m²，月租 ¥45,144 |
| 3 | 2028-01 ~ 2029-12 | 每N年递增 | +8%，单价 ¥110.81/m²，月租 ¥48,756 |

---

### 4.5 合同-单元关联（contract_units）

> **重要**: v1.7 合同-单元为 M:N 关系，`contract_units` 是核心中间表。`invoice_service` 自动账单生成、WALE 计算均从此表读取计费面积和单价。

| contract_id | unit_id | billing_area (m²) | unit_price (元/m²/月) | 说明 |
|-------------|---------|------------------|----------------------|------|
| C-OFFICE-01 | 10A | 280.00 | 110.00 | 明辉科技 — 套内面积A |
| C-OFFICE-01 | 10B | 140.00 | 105.00 | 明辉科技 — 套内面积B |
| C-RETAIL-01 | S101 | 108.00 | 230.00 | 聚鑭餐饮（保底基准单价）|
| C-APT-01 | A302 | 55.00 | null | 公寓整套月租，unit_price 为 null，计费以合同定额 ¥4,761.90 为准 |
| C-SUB-MASTER | 20A | 440.00 | 95.00 | 鼎盛物业（2024~2025年基准单价）|

---

### 4.6 租金递增阶段（rent_escalation_phases）

> 每行对应 `rent_escalation_phases` 表中一条记录；`params_json` 由 `rent_escalation_engine` 包解析。C-APT-01 无递增阶段（1 年短租不设递增）。

| phase_id | contract_id | phase_order | start_date | end_date | escalation_type | params_json |
|---------|-------------|------------|-----------|---------|----------------|-------------|
| EP-01-1 | C-OFFICE-01 | 1 | 2025-06-01 | 2027-05-31 | `base_after_free_period` | `{}` |
| EP-01-2 | C-OFFICE-01 | 2 | 2027-06-01 | 2028-05-31 | `fixed_rate` | `{"rate": 0.05}` |
| EP-02-1 | C-RETAIL-01 | 1 | 2025-03-01 | 2026-02-28 | `step` | `{"base_price": 230.00}` |
| EP-02-2 | C-RETAIL-01 | 2 | 2026-03-01 | 2027-02-28 | `step` | `{"base_price": 250.00}` |
| EP-02-3 | C-RETAIL-01 | 3 | 2027-03-01 | 2028-02-28 | `step` | `{"base_price": 270.00}` |
| EP-SUB-1 | C-SUB-MASTER | 1 | 2024-01-01 | 2025-12-31 | `base_after_free_period` | `{}` |
| EP-SUB-2 | C-SUB-MASTER | 2 | 2026-01-01 | 2027-12-31 | `periodic` | `{"rate": 0.08, "interval_years": 2}` |
| EP-SUB-3 | C-SUB-MASTER | 3 | 2028-01-01 | 2029-12-31 | `periodic` | `{"rate": 0.08, "interval_years": 2}` |

---

## 五、子租赁种子（二房东穿透数据）

主合同: C-SUB-MASTER（鼎盛物业，20A 单元拆分转租）

| sub_lease_id | unit_number | end_tenant | tenant_type | monthly_rent | unit_price | start_date | end_date | occupancy_status | review_status |
|-------------|-------------|-----------|------------|-------------|-----------|-----------|---------|-----------------|--------------|
| SL-001 | 20A-01 | 旭日软件有限公司 | corporate | ¥12,000 | ¥120/m² | 2025-01-01 | 2025-12-31 | occupied | approved |
| SL-002 | 20A-02 | 星光广告有限公司 | corporate | ¥8,500 | ¥118/m² | 2025-03-01 | 2026-02-28 | occupied | approved |
| SL-003 | 20A-03 | （空置） | — | — | — | — | — | vacant | approved |

**穿透分析验算**：

| 指标 | 计算 | 结果 |
|------|------|------|
| 二房东主合同单价 | ¥95/m²（2025年） | — |
| 终端平均租金单价 | (120 + 118) / 2 | ¥119/m² |
| 溢价率 | (119 - 95) / 95 × 100% | **25.26%** |
| 穿透出租率 | (100 + 72) / 440 × 100% | **39.09%**（假设子单元面积） |

---

## 六、账单种子

### 6.1 正常账单

| invoice_id | contract | period | item_type | amount (不含税) | tax | total | status |
|-----------|---------|--------|-----------|---------------|-----|-------|--------|
| INV-001 | C-OFFICE-01 | 2025-07 | rent | ¥45,500.00 | ¥4,095.00 | ¥49,595.00 | paid |
| INV-002 | C-OFFICE-01 | 2025-07 | management_fee | ¥6,300.00 | ¥567.00 | ¥6,867.00 | paid |
| INV-003 | C-RETAIL-01 | 2025-07 | rent | ¥28,000.00 | ¥1,400.00 | ¥29,400.00 | issued |
| INV-004 | C-APT-01 | 2025-07 | rent | ¥4,761.90 | ¥238.10 | ¥5,000.00 | overdue |
| INV-005 | C-OFFICE-01 | 2025-06 | rent | ¥24,266.67 | ¥2,184.00 | ¥26,450.67 | paid |

### 6.2 免租期账单

| invoice_id | contract | period | item_type | amount | status | 备注 |
|-----------|---------|--------|-----------|--------|--------|------|
| INV-006 | C-RETAIL-01 | 2025-03 | rent | ¥0.00 | exempt | 免租月 |
| INV-007 | C-RETAIL-01 | 2025-04 | rent | ¥0.00 | exempt | 免租月 |
| INV-008 | C-RETAIL-01 | 2025-05 | rent | ¥0.00 | exempt | 免租月 |

### 6.3 账单明细（invoice_items）

> 每张账单可含多条费项明细：INV-001 展示多单元拆分计费，INV-003 展示分成溢价明细，INV-005 展示免租当月折算明细。

| item_id | invoice_id | item_type | description | amount (不含税) | tax | total |
|---------|-----------|---------|-------------|---------------|-----|-------|
| II-001-1 | INV-001 | rent | 10A租金（280m²×¥110） | ¥30,800.00 | ¥2,772.00 | ¥33,572.00 |
| II-001-2 | INV-001 | rent | 10B租金（140m²×¥105） | ¥14,700.00 | ¥1,323.00 | ¥16,023.00 |
| II-002-1 | INV-002 | management_fee | 物管费（420m²×¥15） | ¥6,300.00 | ¥567.00 | ¥6,867.00 |
| II-003-1 | INV-003 | rent | S101 保底租金（108m²×¥230） | ¥24,840.00 | ¥1,242.00 | ¥26,082.00 |
| II-003-2 | INV-003 | revenue_share | 7月营业额分成溢价（350,000×8%−24,840） | ¥3,160.00 | ¥158.00 | ¥3,318.00 |
| II-004-1 | INV-004 | rent | A302 整套月租（含税折算不含税） | ¥4,761.90 | ¥238.10 | ¥5,000.00 |
| II-005-1 | INV-005 | rent | 10A 6月免租后折算（280m²×¥110×16/30） | ¥16,426.67 | ¥1,478.40 | ¥17,905.07 |
| II-005-2 | INV-005 | rent | 10B 6月免租后折算（140m²×¥105×16/30） | ¥7,840.00 | ¥705.60 | ¥8,545.60 |

> **II-005 合计验算**: ¥16,426.67 + ¥7,840.00 = ¥24,266.67（不含税）；含税 ¥24,266.67 × 1.09 = **¥26,450.67**，与 INV-005 主记录一致。

---

## 七、押金种子

| deposit_id | contract | amount | status | 说明 |
|-----------|---------|--------|--------|------|
| DEP-001 | C-OFFICE-01 | ¥136,500 | collected | 3个月押金已收 |
| DEP-002 | C-RETAIL-01 | ¥149,040 | collected | 6个月押金已收 |
| DEP-003 | C-APT-01 | ¥10,000 | collected | 2个月押金已收 |
| DEP-004 | C-SUB-MASTER | ¥250,800 | collected | 6个月押金已收 |

### 7.2 押金流水（deposit_transactions）

| txn_id | deposit_id | txn_type | amount | operator_user_id | performed_at | note |
|--------|-----------|---------|--------|-----------------|-------------|------|
| DT-001 | DEP-001 | collected | ¥136,500.00 | U-LEASE | 2025-06-01 | C-OFFICE-01 签约时收取 |
| DT-002 | DEP-002 | collected | ¥149,040.00 | U-LEASE | 2025-03-01 | C-RETAIL-01 签约时收取 |
| DT-003 | DEP-003 | collected | ¥10,000.00 | U-LEASE | 2025-07-01 | C-APT-01 签约时收取 |
| DT-004 | DEP-004 | collected | ¥250,800.00 | U-LEASE | 2024-01-01 | C-SUB-MASTER 签约时收取 |

---

## 八、WALE 验算样本

**计算基准日**: 2025-08-01

| 合同 | 到期日 | 剩余天数 | 剩余年 | 年化租金 (不含税) | 计费面积 |
|------|-------|---------|-------|-----------------|---------|
| C-OFFICE-01 | 2028-05-31 | 1035 | 2.836 | ¥546,000 | 420 m² |
| C-RETAIL-01 | 2028-02-28 | 942 | 2.581 | ¥297,600*（取保底） | 108 m² |
| C-APT-01 | 2026-06-30 | 334 | 0.915 | ¥57,142.80 | 55 m² |
| C-SUB-MASTER | 2029-12-31 | 1614 | 4.422 | ¥501,600 | 440 m² |

> *C-RETAIL-01 年化租金取保底口径（24,840×12=297,600）。实际分成差额部分不纳入 WALE 基础年化租金。

$$WALE_{\text{收入}} = \frac{2.836 \times 546000 + 2.581 \times 297600 + 0.915 \times 57142.80 + 4.422 \times 501600}{546000 + 297600 + 57142.80 + 501600}$$

$$= \frac{1548456 + 768106 + 52286 + 2218075}{1402343} = \frac{4586923}{1402343} \approx \textbf{3.27 年}$$

$$WALE_{\text{面积}} = \frac{2.836 \times 420 + 2.581 \times 108 + 0.915 \times 55 + 4.422 \times 440}{420 + 108 + 55 + 440}$$

$$= \frac{1191.12 + 278.75 + 50.33 + 1945.68}{1023} = \frac{3465.88}{1023} \approx \textbf{3.39 年}$$

---

## 九、NOI 验算样本（2025年7月）

### 收入侧（EGI）

| 项目 | 金额(不含税/月) | 说明 |
|------|-------------|------|
| C-OFFICE-01 租金 | ¥45,500 | |
| C-OFFICE-01 物管费 | ¥6,300 | |
| C-RETAIL-01 租金 | ¥28,000 | 7月营业额 ¥350,000，MAX(24840, 28000) |
| C-APT-01 租金 | ¥4,761.90 | |
| C-SUB-MASTER 租金 | ¥41,800 | |
| **PGI (实际应收)** | **¥126,361.90** | |
| 空置损失估算 | -¥14,750 | 空置单元按 market_rent_reference 估算 |
| **EGI** | **¥111,611.90** | |

### 支出侧（OpEx）

| 类目 | 金额/月 |
|------|--------|
| 水电公摊 | ¥8,500 |
| 外包物业费 | ¥15,000 |
| 维修费（含工单） | ¥3,200 |
| 保险 | ¥2,000 |
| 税金 | ¥5,000 |
| **OpEx 合计** | **¥33,700** |

### NOI

$$NOI = EGI - OpEx = 111,611.90 - 33,700 = \textbf{¥77,911.90}$$

---

## 十、KPI 打分验算样本

**方案**: "租务部考核方案 2026Q3"（季度考核）  
**评估对象**: 租务专员 王五  
**管辖范围**: A座 10F~20F

| 指标 | 权重 | 满分标准 | 及格标准 | 实际值 | 方向 | 得分计算 | 得分 |
|------|------|---------|---------|-------|------|---------|------|
| K01 出租率 | 25% | ≥95% | ≥80% | 91% | 正向 | 60 + (91-80)/(95-80) × 40 = 89.33 | 89.33 |
| K02 收款及时率 | 20% | ≥95% | ≥80% | 98% | 正向 | 100 (≥满分) | 100.00 |
| K04 续约率 | 15% | ≥80% | ≥60% | 75% | 正向 | 60 + (75-60)/(80-60) × 40 = 90.00 | 90.00 |
| K06 空置周转天数 | 15% | ≤30天 | ≤60天 | 25天 | 反向 | 100 (≤满分标准) | 100.00 |
| K08 逾期率 | 15% | ≤5% | ≤15% | 8% | 反向 | 60 + (15-8)/(15-5) × 40 = 88.00 | 88.00 |
| K09 递增执行率 | 10% | ≥95% | ≥80% | 100% | 正向 | 100 | 100.00 |

$$KPI_{总分} = 89.33 \times 0.25 + 100 \times 0.20 + 90 \times 0.15 + 100 \times 0.15 + 88 \times 0.15 + 100 \times 0.10$$

$$= 22.33 + 20.00 + 13.50 + 15.00 + 13.20 + 10.00 = \textbf{94.03 分}$$

---

## 十一、工单种子

| work_order_id | unit | category | priority | status | reporter_user_id | supplier_id | actual_cost | note |
|-------------|------|----------|----------|--------|-----------------|------------|------------|------|
| WO-001 | 10A | 空调维修 | urgent | completed | U-FRONT | SUP-001 | ¥850.00 | 已完工，费用计入 EXP-003 |
| WO-002 | A302 | 水管漏水 | critical | in_progress | U-FRONT | SUP-002 | — | 处理中，待验收 |
| WO-003 | S101 | 门锁更换 | normal | submitted | U-FRONT | — | — | 未派单，待分配供应商 |

---

## 十二、用户与部门种子

### 部门

| dept_id | name | parent | level |
|---------|------|--------|-------|
| D-ROOT | 鼎悦资产管理公司 | null | 1 |
| D-LEASE | 租务部 | D-ROOT | 2 |
| D-FIN | 财务部 | D-ROOT | 2 |
| D-OPS | 物业运营部 | D-ROOT | 2 |
| D-LEASE-OFFICE | 写字楼组 | D-LEASE | 3 |
| D-LEASE-APT | 公寓组 | D-LEASE | 3 |

### 用户

| user_id | name | email | role | department | bound_contract_id |
|---------|------|-------|------|-----------|------------------|
| U-ADMIN | 管理员 | admin@propos.local | super_admin | D-ROOT | null |
| U-MGR | 陈经理 | chen.mgr@propos.local | operations_manager | D-OPS | null |
| U-LEASE | 王五 | wang.lease@propos.local | leasing_specialist | D-LEASE-OFFICE | null |
| U-FIN | 李财务 | li.fin@propos.local | finance_staff | D-FIN | null |
| U-FRONT | 赵前线 | zhao.front@propos.local | frontline_staff | D-OPS | null |
| U-SUBLORD | 鼎盛物业 | dingsheng@external.com | sub_landlord | null | **C-SUB-MASTER** |

> **U-SUBLORD 关键**: `bound_contract_id = C-SUB-MASTER` 实现二房东 RBAC 行级隔离——这个字段缺失时 `SubleaseRepository` 的 `WHERE master_contract_id = $bound_contract_id` 过滤将失效。

---

## 十三、水电抄表种子

| meter_reading_id | unit | meter_type | reading_cycle | previous_reading | current_reading | usage | unit_price | amount |
|-----------------|------|-----------|--------------|-----------------|----------------|-------|-----------|--------|
| MR-001 | 10A | electricity | monthly | 12450 | 13280 | 830 kWh | ¥1.20 | ¥996.00 |
| MR-002 | 10A | water | monthly | 856 | 878 | 22 m³ | ¥5.60 | ¥123.20 |
| MR-003 | S101 | electricity | monthly | 8900 | 10150 | 1250 kWh | ¥1.20 | ¥1,500.00 |

---

---

## 十四、收款与核销种子

### 14.1 收款主记录（payments）

| payment_id | received_by_user_id | received_at | total_amount | payment_method | note |
|-----------|--------------------|-----------:|-------------|----------------|------|
| PAY-001 | U-FIN | 2025-07-05 | ¥56,462.00 | bank_transfer | C-OFFICE-01 2025-Q3 租金+物管费合并转账 |
| PAY-002 | U-FIN | 2025-06-30 | ¥26,450.67 | bank_transfer | C-OFFICE-01 2025-06 免租后折算 |
| PAY-003 | U-FIN | 2025-01-05 | ¥125,400.00 | bank_transfer | C-SUB-MASTER 2024-Q4 季付（含税 ¥41,800×3×1.09≈¥136,806，此处为Q4不含税简化） |

### 14.2 核销分配（payment_allocations）

| alloc_id | payment_id | invoice_id | allocated_amount | note |
|---------|-----------|-----------|-----------------|------|
| PA-001 | PAY-001 | INV-001 | ¥49,595.00 | 7月租金核销 |
| PA-002 | PAY-001 | INV-002 | ¥6,867.00 | 7月物管费核销 |
| PA-003 | PAY-002 | INV-005 | ¥26,450.67 | 6月免租折算核销 |

> **验算**: PAY-001 分配合计 ¥49,595 + ¥6,867 = **¥56,462.00**，与 payment.total_amount 一致。

---

## 十五、运营支出种子（expenses）

> 对应第九章 NOI 验算 OpEx 侧数据，2025年7月月度支出。`building_id` 均为 B-OFFICE。

| expense_id | category | amount | period_month | building_id | description |
|-----------|---------|--------|-------------|-------------|-------------|
| EXP-001 | utility_common | ¥8,500.00 | 2025-07 | B-OFFICE | 公共区域水电费（走廊/电梯/大堂） |
| EXP-002 | outsourced_property | ¥15,000.00 | 2025-07 | B-OFFICE | 外包物业公司月度服务费 |
| EXP-003 | repair | ¥850.00 | 2025-07 | B-OFFICE | WO-001 空调维修结算（对应 SUP-001） |
| EXP-004 | repair | ¥2,350.00 | 2025-07 | B-OFFICE | 其他小修工单汇总 |
| EXP-005 | insurance | ¥2,000.00 | 2025-07 | B-OFFICE | 财产险月度摊销 |
| EXP-006 | tax | ¥5,000.00 | 2025-07 | B-OFFICE | 房产税月度摊销 |

> **OpEx 合计**: ¥8,500 + ¥15,000 + ¥850 + ¥2,350 + ¥2,000 + ¥5,000 = **¥33,700**，与第九章 NOI 验算一致。

---

## 十六、供应商种子（suppliers）

| supplier_id | name | contact_person | contact_phone | service_category | is_active |
|------------|------|---------------|--------------|-----------------|----------|
| SUP-001 | 顺达空调服务公司 | 张技工 | 13800110001 | 空调维修 | true |
| SUP-002 | 鼎盛水电工程公司 | 李师傅 | 13700220002 | 水电维修 | true |
| SUP-003 | 安居锁业有限公司 | 王师傅 | 13600330003 | 门锁安防 | true |

> 工单对应关系：WO-001 → SUP-001；WO-002 → SUP-002；WO-003 待派单 → 预计 SUP-003。

---

## 十七、商铺营业额申报（turnover_reports）

| report_id | contract_id | period_month | turnover_amount | approval_status | reviewed_by | base_rent | revenue_share_rate | revenue_share_amount | final_invoice_amount | note |
|----------|-------------|-------------|----------------|----------------|-------------|----------|-------------------|---------------------|---------------------|------|
| TR-001 | C-RETAIL-01 | 2025-06 | ¥250,000 | approved | U-FIN | ¥24,840 | 8% | ¥20,000 | **¥24,840** | MAX→保底 |
| TR-002 | C-RETAIL-01 | 2025-07 | ¥350,000 | approved | U-FIN | ¥24,840 | 8% | ¥28,000 | **¥28,000** | MAX→分成；对应 INV-003 |
| TR-003 | C-RETAIL-01 | 2025-08 | ¥310,000 | approved | U-FIN | ¥24,840 | 8% | ¥24,800 | **¥24,840** | MAX→保底（边界±¥40） |
| TR-004 | C-RETAIL-01 | 2025-09 | ¥500,000 | pending | null | ¥24,840 | 8% | ¥40,000 | 待定 | 待审核，账单未生成 |

---

## 十八、改造记录种子（renovation_records）

| record_id | unit_id | renovation_type | start_date | end_date | cost | description | has_photo |
|----------|---------|----------------|-----------|---------|------|-------------|----------|
| REN-001 | 10A | 精装修改造 | 2024-03-01 | 2024-05-15 | ¥180,000 | 交付前精装修，含隔断、地毯、灯具 | true |
| REN-002 | S103 | 结构改造 | 2023-11-01 | 2024-01-31 | ¥85,000 | 打通隔墙，扩大临街面，施工期单元空置 | true |
| REN-003 | A302 | 基础翻新 | 2025-05-15 | 2025-06-30 | ¥12,000 | 签约前基础翻新，刷漆+更换洁具 | false |

> 照片存储路径格式：`renovations/{record_uuid}/{index}.jpg`。

---

## 十九、预警记录种子（alerts）

| alert_id | contract_id | alert_type | triggered_at | is_sent | sent_at | retry_count | note |
|---------|------------|----------|-------------|--------|--------|------------|------|
| ALT-001 | C-APT-01 | lease_expiry_90 | 2026-04-01 | true | 2026-04-01 | 0 | 公寓合同 90 天到期预警（已发送） |
| ALT-002 | C-APT-01 | lease_expiry_60 | 2026-05-01 | false | null | 0 | 待触发（定时任务 2026-05-01 执行） |
| ALT-003 | C-APT-01 | payment_overdue_1 | 2025-08-01 | true | 2025-08-01 | 0 | INV-004 逾期第 1 天（7月账单未收款） |
| ALT-004 | C-APT-01 | payment_overdue_7 | 2025-08-07 | true | 2025-08-07 | 1 | INV-004 逾期第 7 天（首次失败，已重试 1 次） |
| ALT-005 | C-OFFICE-01 | lease_expiry_90 | 2028-03-02 | false | null | 0 | 写字楼合同 2028-05-31 到期，未来触发 |
| ALT-006 | C-SUB-MASTER | deposit_refund_reminder | 2029-12-24 | false | null | 0 | 押金退还提醒（合同终止前 7 天） |

---

## 二十、管辖范围种子（user_managed_scopes）

> 个人范围覆盖部门默认（个人 > 部门），KPI 数据归集以最终有效范围为准。

### 20.1 部门默认管辖范围

| scope_id | department_id | building_id | floor_id | note |
|---------|--------------|------------|---------|------|
| MS-D-001 | D-LEASE | B-OFFICE | null | 租务部默认管辖 A 座整栋 |
| MS-D-002 | D-LEASE | B-RETAIL | null | 租务部默认管辖商铺区 |
| MS-D-003 | D-LEASE | B-APT | null | 租务部默认管辖公寓楼 |
| MS-D-004 | D-FIN | B-OFFICE | null | 财务部管辖 A 座 |
| MS-D-005 | D-FIN | B-RETAIL | null | 财务部管辖商铺区 |
| MS-D-006 | D-FIN | B-APT | null | 财务部管辖公寓楼 |
| MS-D-007 | D-OPS | B-OFFICE | null | 运营部管辖 A 座 |
| MS-D-008 | D-OPS | B-RETAIL | null | 运营部管辖商铺区 |
| MS-D-009 | D-OPS | B-APT | null | 运营部管辖公寓楼 |

### 20.2 员工个人覆盖范围（U-LEASE 王五 — 仅管辖 A 座 10F 和 20F）

| scope_id | user_id | building_id | floor_id | note |
|---------|--------|------------|---------|------|
| MS-U-001 | U-LEASE | B-OFFICE | F-10F（A座10F） | KPI 验算范围：含 10A、10B、10C |
| MS-U-002 | U-LEASE | B-OFFICE | F-20F（A座20F） | KPI 验算范围：含 20A（含二房东主合同） |

> **KPI 数据归集**: U-LEASE 的个人配置覆盖部门默认范围，指标仅汇总 10F 和 20F 的数据。

---

## 二十一、NOI 预算种子（noi_budgets）

> K07 NOI 达成率 = 实际 NOI ÷ 预算 NOI，需提前录入各楼栋月度预算。

| budget_id | building_id | period_month | budget_pgi | budget_vacancy_loss | budget_other_income | budget_opex | budget_noi |
|----------|------------|-------------|-----------|-------------------|-------------------|------------|-----------|
| BUD-001 | B-OFFICE | 2025-07 | ¥130,000.00 | ¥15,000.00 | ¥0.00 | ¥35,000.00 | **¥80,000.00** |

**K07 达成率验算**：

| 指标 | 计算 | 结果 |
|------|------|------|
| 预算 NOI | ¥130,000 − ¥15,000 + ¥0 − ¥35,000 | ¥80,000.00 |
| 实际 NOI | 见第九章 | ¥77,911.90 |
| NOI 达成率 | ¥77,911.90 / ¥80,000 | **97.39%** |
| K07 得分（满分 ≥100%，及格 ≥90%） | 60 + (97.39−90)/(100−90) × 40 | **89.56 分** |

---

## 二十二、KPI 指标库（kpi_metric_definitions）

> 10 条系统预定义指标由 seed 写入，管理员可启用/停用，不可自行删除。`direction` 字段决定线性插值逻辑方向。

| metric_id | code | name | direction | default_full_score_threshold | default_pass_threshold | unit | data_source_key |
|---------|------|------|---------|--------------------------|---------------------|------|----------------|
| KM-K01 | K01 | 出租率 | positive | 0.95 | 0.80 | 比例 | assets.leasable_ratio |
| KM-K02 | K02 | 收款及时率 | positive | 0.95 | 0.80 | 比例 | finance.payment_on_time_rate |
| KM-K03 | K03 | 租户集中度 | negative | 0.40 | 0.60 | 比例（越低越好）| contracts.top3_rent_concentration |
| KM-K04 | K04 | 续约率 | positive | 0.80 | 0.60 | 比例 | contracts.renewal_rate |
| KM-K05 | K05 | 工单响应时效 | negative | 24 | 72 | 小时（越少越好）| workorders.avg_response_hours |
| KM-K06 | K06 | 空置周转天数 | negative | 30 | 60 | 天（越少越好）| assets.avg_vacancy_days |
| KM-K07 | K07 | NOI 达成率 | positive | 1.00 | 0.90 | 比例 | finance.noi_achievement_rate |
| KM-K08 | K08 | 逾期率 | negative | 0.05 | 0.15 | 比例（越低越好）| finance.overdue_rate |
| KM-K09 | K09 | 租金递增执行率 | positive | 0.95 | 0.80 | 比例 | contracts.escalation_execution_rate |
| KM-K10 | K10 | 租户满意度 | positive | 90 | 70 | 分（0~100）| manual.satisfaction_score |

---

## 二十三、KPI 考核方案种子

### 23.1 考核方案（kpi_schemes）

| scheme_id | name | period_type | effective_from | effective_to | is_active |
|----------|------|------------|---------------|------------|---------|
| KS-001 | 租务部考核方案 2026Q3 | quarterly | 2025-07-01 | 2025-09-30 | true |
| KS-002 | 全员 KPI 月度试行方案 | monthly | 2025-07-01 | 2025-07-31 | false |

### 23.2 方案-指标关联（kpi_scheme_metrics）

> KS-001 启用 6 项指标（K01/K02/K04/K06/K08/K09），权重合计 **100%**。

| id | scheme_id | metric_id | weight | full_score_threshold | pass_threshold | is_enabled |
|----|----------|---------|------|---------------------|--------------|----------|
| KSM-001 | KS-001 | KM-K01 | 0.25 | 0.95 | 0.80 | true |
| KSM-002 | KS-001 | KM-K02 | 0.20 | 0.95 | 0.80 | true |
| KSM-003 | KS-001 | KM-K04 | 0.15 | 0.80 | 0.60 | true |
| KSM-004 | KS-001 | KM-K06 | 0.15 | 30 | 60 | true |
| KSM-005 | KS-001 | KM-K08 | 0.15 | 0.05 | 0.15 | true |
| KSM-006 | KS-001 | KM-K09 | 0.10 | 0.95 | 0.80 | true |

### 23.3 方案绑定对象（kpi_scheme_targets）

| id | scheme_id | user_id | department_id | note |
|----|---------|--------|--------------|------|
| KST-001 | KS-001 | U-LEASE | null | 王五个人考核 |
| KST-002 | KS-001 | null | D-LEASE | 租务部整体考核（汇总部门数据） |

---

## 二十四、KPI 评分快照种子

### 24.1 快照主记录（kpi_score_snapshots）

| snapshot_id | scheme_id | evaluated_user_id | period_start | period_end | status | total_score | created_at |
|------------|----------|-----------------|-------------|----------|--------|------------|-----------|
| SNAP-001 | KS-001 | U-LEASE | 2025-07-01 | 2025-09-30 | frozen | 94.03 | 2025-10-01 |

### 24.2 快照明细（kpi_score_snapshot_items）

| item_id | snapshot_id | metric_id | actual_value | score | weighted_score | note |
|--------|-----------|---------|------------|------|--------------|------|
| SNAPI-001 | SNAP-001 | KM-K01 | 0.91 | 89.33 | 22.33 | 60+(91%-80%)/(95%-80%)×40 |
| SNAPI-002 | SNAP-001 | KM-K02 | 0.98 | 100.00 | 20.00 | ≥满分标准 |
| SNAPI-003 | SNAP-001 | KM-K04 | 0.75 | 90.00 | 13.50 | 60+(75%-60%)/(80%-60%)×40 |
| SNAPI-004 | SNAP-001 | KM-K06 | 25 | 100.00 | 15.00 | ≤满分标准（25天≤30天）|
| SNAPI-005 | SNAP-001 | KM-K08 | 0.08 | 88.00 | 13.20 | 反向：60+(15%-8%)/(15%-5%)×40 |
| SNAPI-006 | SNAP-001 | KM-K09 | 1.00 | 100.00 | 10.00 | ≥满分标准 |

> **合计验算**: 22.33 + 20.00 + 13.50 + 15.00 + 13.20 + 10.00 = **94.03 分**，与第十章一致。

### 24.3 KPI 申诉（kpi_appeals）

| appeal_id | snapshot_id | appellant_id | reason | status | reviewer_id | submitted_at |
|----------|-----------|------------|-------|--------|------------|-------------|
| APP-001 | SNAP-001 | U-LEASE | K01 出租率 91%，本季度 10C 单元 9 月完成签约但系统未及时更新，实际出租率应为 93%，申请重算 | pending | null | 2025-10-05 |

---

> **使用说明**:  
> 1. 开发时可直接基于本文档编写 `scripts/seed.sql` 或测试 fixture  
> 2. 所有金额均为示意，实际部署前需替换为真实数据  
> 3. UUID 简称（如 C-OFFICE-01、KM-K01）在 SQL 中替换为 `gen_random_uuid()` 生成的真实 UUID  
> 4. 验算结果（WALE、NOI、KPI）可作为单元测试的 expected 值  
> 5. P0 强依赖（必须先于业务代码写入）：`kpi_metric_definitions`（10条）、`departments`（6条）、`users`（6条）、`buildings`（3条）  
> 6. 种子执行顺序参考：departments → buildings → floors → users → suppliers → units → tenants → contracts → contract_units → rent_escalation_phases → deposits → deposit_transactions → invoices → invoice_items → payments → payment_allocations → expenses → meter_readings → alerts → renovation_records → turnover_reports → subleases → kpi_metric_definitions → kpi_schemes → kpi_scheme_metrics → kpi_scheme_targets → noi_budgets → user_managed_scopes → kpi_score_snapshots → kpi_score_snapshot_items → kpi_appeals → work_orders
