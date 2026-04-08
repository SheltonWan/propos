# PropOS 种子数据业务样本规格

> **版本**: v1.0  
> **日期**: 2026-04-08  
> **依据**: PRD v1.7 / data_model v1.3 / API_CONTRACT v1.7  
> **用途**: 为开发自测、单元测试、集成测试与 WALE/NOI/KPI 验算提供标准化参考数据  

---

## 一、楼栋与楼层种子

| building_id (简称) | name | property_type | total_floors | gfa (m²) | nla (m²) |
|-------------------|------|---------------|-------------|----------|----------|
| B-OFFICE | A座 | office | 20 | 30000.00 | 25500.00 |
| B-RETAIL | 商铺区 | retail | 2 | 2707.00 | 2300.00 |
| B-APT | 公寓楼 | apartment | 8 | 7300.00 | 6200.00 |

### 楼层样本（A座）

| floor_number | floor_name | nla (m²) |
|-------------|------------|----------|
| -1 | B1 | 0.00 |
| 1 | 1F | 1200.00 |
| 2 | 2F | 1350.00 |
| 10 | 10F | 1350.00 |
| 20 | 20F | 1200.00 |

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
| 2025-06（前14天免租） | ¥16,613.33 | ¥7,933.33 | ¥24,546.66 | 按 (30-14)/30 折算 |
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
| INV-005 | C-OFFICE-01 | 2025-06 | rent | ¥24,546.66 | ¥2,209.20 | ¥26,755.86 | paid |

### 6.2 免租期账单

| invoice_id | contract | period | item_type | amount | status | 备注 |
|-----------|---------|--------|-----------|--------|--------|------|
| INV-006 | C-RETAIL-01 | 2025-03 | rent | ¥0.00 | exempt | 免租月 |
| INV-007 | C-RETAIL-01 | 2025-04 | rent | ¥0.00 | exempt | 免租月 |
| INV-008 | C-RETAIL-01 | 2025-05 | rent | ¥0.00 | exempt | 免租月 |

---

## 七、押金种子

| deposit_id | contract | amount | status | 说明 |
|-----------|---------|--------|--------|------|
| DEP-001 | C-OFFICE-01 | ¥136,500 | collected | 3个月押金已收 |
| DEP-002 | C-RETAIL-01 | ¥149,040 | collected | 6个月押金已收 |
| DEP-003 | C-APT-01 | ¥10,000 | collected | 2个月押金已收 |
| DEP-004 | C-SUB-MASTER | ¥250,800 | collected | 6个月押金已收 |

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

| work_order_id | unit | category | priority | status | reporter | assignee | cost |
|-------------|------|----------|----------|--------|----------|----------|------|
| WO-001 | 10A | 空调维修 | urgent | completed | 前线员工A | 供应商-空调 | ¥850 |
| WO-002 | A302 | 水管漏水 | critical | in_progress | 前线员工B | 供应商-水电 | — |
| WO-003 | S101 | 门锁更换 | normal | submitted | 前线员工A | — | — |

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

| user_id | name | email | role | department |
|---------|------|-------|------|-----------|
| U-ADMIN | 管理员 | admin@propos.local | super_admin | D-ROOT |
| U-MGR | 陈经理 | chen.mgr@propos.local | operations_manager | D-OPS |
| U-LEASE | 王五 | wang.lease@propos.local | leasing_specialist | D-LEASE-OFFICE |
| U-FIN | 李财务 | li.fin@propos.local | finance_staff | D-FIN |
| U-FRONT | 赵前线 | zhao.front@propos.local | frontline_staff | D-OPS |
| U-SUBLORD | 鼎盛物业 | dingsheng@external.com | sub_landlord | null |

---

## 十三、水电抄表种子

| meter_reading_id | unit | meter_type | reading_cycle | previous_reading | current_reading | usage | unit_price | amount |
|-----------------|------|-----------|--------------|-----------------|----------------|-------|-----------|--------|
| MR-001 | 10A | electricity | monthly | 12450 | 13280 | 830 kWh | ¥1.20 | ¥996.00 |
| MR-002 | 10A | water | monthly | 856 | 878 | 22 m³ | ¥5.60 | ¥123.20 |
| MR-003 | S101 | electricity | monthly | 8900 | 10150 | 1250 kWh | ¥1.20 | ¥1,500.00 |

---

> **使用说明**:  
> 1. 开发时可直接基于本文档编写 `scripts/seed.sql` 或测试 fixture  
> 2. 所有金额均为示意，实际部署前需替换为真实数据  
> 3. UUID 简称（如 C-OFFICE-01）在 SQL 中替换为 `gen_random_uuid()` 生成的真实 UUID  
> 4. 验算结果（WALE、NOI、KPI）可作为单元测试的 expected 值
