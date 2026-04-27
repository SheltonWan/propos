/**
 * 单元台账导入模板（CSV）— 客户端生成，零依赖
 *
 * 列规格依据 docs/backend/IMPORT_TEMPLATE_SPEC.md §二
 * 同一张表可混合写字楼/商铺/公寓行（col3 指定业态），支持综合体楼栋
 *
 * 列顺序（后端 unit_service.dart 严格对齐）：
 *   0  楼栋名称
 *   1  楼层名称
 *   2  单元编号
 *   3  业态（写字楼/商铺/公寓；为空时继承楼栋业态）
 *   4  建筑面积(m²)
 *   5  套内面积(m²)
 *   6  朝向
 *   7  层高(m)
 *   8  装修状态
 *   9  是否可租
 *  10  参考市场租金
 *  11  业态专属字段1（写字楼:工位数 / 商铺:门面宽度 / 公寓:卧室数）
 *  12  业态专属字段2（写字楼:分隔间数 / 商铺:是否临街 / 公寓:独立卫生间）
 *  13  业态专属字段3（商铺:商铺层高；其他业态留空）
 *
 * UTF-8 BOM 必须保留，否则 Excel 默认 GBK 解码会乱码
 */

import type { PropertyType } from '@/types/asset'

interface TemplateSpec {
  filename: string
  headers: string[]
  /** 表头下方的提示行（# 开头会被后端忽略，仅供人工查看） */
  hints: string[]
  sampleRows: string[][]
}

// 通用前 11 列（楼栋…参考租金），三业态一致
const COMMON_LEAD_HEADERS = [
  '楼栋名称',
  '楼层名称',
  '单元编号',
  '业态',
  '建筑面积(m²)',
  '套内面积(m²)',
  '朝向',
  '层高(m)',
  '装修状态',
  '是否可租',
  '参考市场租金',
]

// 综合体（混合业态）模板用通用占位列名
const MIXED_HEADERS = [
  ...COMMON_LEAD_HEADERS,
  '业态专属字段1',
  '业态专属字段2',
  '业态专属字段3',
]

const OFFICE_TEMPLATE: TemplateSpec = {
  filename: '单元台账_写字楼.csv',
  headers: [...COMMON_LEAD_HEADERS, '工位数', '分隔间数'],
  hints: [
    '# 业态: 写字楼/商铺/公寓（为空则继承楼栋业态）；朝向: 东/南/西/北',
    '# 装修状态: 毛坯/简装/精装/原始；是否可租: 是/否',
    '# 楼栋名称、楼层名称必须已在系统中存在；单元编号同楼栋内唯一',
  ],
  sampleRows: [
    ['A座', '25F', 'A-25-2501', '写字楼', '135.0', '120.5', '南', '3.2', '精装', '是', '85.0', '15', '3'],
    ['A座', '25F', 'A-25-2502', '写字楼', '95.0', '80.0', '东', '3.2', '简装', '是', '85.0', '10', '2'],
  ],
}

const RETAIL_TEMPLATE: TemplateSpec = {
  filename: '单元台账_商铺.csv',
  headers: [...COMMON_LEAD_HEADERS, '门面宽度(m)', '是否临街', '商铺层高(m)'],
  hints: [
    '# 业态: 写字楼/商铺/公寓（为空则继承楼栋业态）；朝向: 东/南/西/北',
    '# 装修状态: 毛坯/简装/精装/原始；是否可租/是否临街: 是/否',
    '# 楼栋名称、楼层名称必须已在系统中存在；单元编号同楼栋内唯一',
  ],
  sampleRows: [
    ['商铺区', '1F', 'S-01-101', '商铺', '120.0', '100.0', '南', '4.5', '原始', '是', '180.0', '6.0', '是', '4.5'],
    ['商铺区', '1F', 'S-01-102', '商铺', '60.0', '50.0', '南', '4.5', '原始', '是', '180.0', '3.5', '是', '4.5'],
  ],
}

const APARTMENT_TEMPLATE: TemplateSpec = {
  filename: '单元台账_公寓.csv',
  headers: [...COMMON_LEAD_HEADERS, '卧室数', '独立卫生间'],
  hints: [
    '# 业态: 写字楼/商铺/公寓（为空则继承楼栋业态）；朝向: 东/南/西/北',
    '# 公寓的"参考市场租金"为整套月租（不是 元/m²/月）；独立卫生间: 是/否',
    '# 楼栋名称、楼层名称必须已在系统中存在；单元编号同楼栋内唯一',
  ],
  sampleRows: [
    ['公寓楼', '5F', 'P-05-501', '公寓', '55.0', '48.0', '南', '2.8', '精装', '是', '4500', '1', '是'],
    ['公寓楼', '5F', 'P-05-502', '公寓', '85.0', '72.0', '南', '2.8', '精装', '是', '7800', '2', '是'],
  ],
}

/** 混合业态示例模板（综合体楼栋专用） */
const MIXED_TEMPLATE: TemplateSpec = {
  filename: '单元台账_综合体.csv',
  headers: MIXED_HEADERS,
  hints: [
    '# 业态: 写字楼/商铺/公寓（同一张表可混合多种业态）',
    '# 写字楼: 字段1=工位数, 字段2=分隔间数, 字段3=留空',
    '# 商铺: 字段1=门面宽度(m), 字段2=是否临街, 字段3=商铺层高(m)',
    '# 公寓: 字段1=卧室数, 字段2=独立卫生间, 字段3=留空',
    '# 楼栋名称、楼层名称必须已在系统中存在；单元编号同楼栋内唯一',
  ],
  sampleRows: [
    ['综合体', '1F', 'S-01-101', '商铺', '120.0', '100.0', '南', '4.5', '原始', '是', '180.0', '6.0', '是', '4.5'],
    ['综合体', '3F', 'O-03-301', '写字楼', '135.0', '120.5', '南', '3.2', '精装', '是', '85.0', '15', '3', ''],
    ['综合体', '10F', 'A-10-1001', '公寓', '55.0', '48.0', '南', '2.8', '精装', '是', '4500', '1', '是', ''],
  ],
}

const TEMPLATES: Record<PropertyType | 'mixed', TemplateSpec> = {
  office: OFFICE_TEMPLATE,
  retail: RETAIL_TEMPLATE,
  apartment: APARTMENT_TEMPLATE,
  mixed: MIXED_TEMPLATE,
}

/** 将单行字段拼为符合 RFC 4180 的 CSV 行 */
function toCsvLine(cells: string[]): string {
  return cells
    .map((c) => {
      const needQuote = /[",\n]/.test(c)
      const escaped = c.replace(/"/g, '""')
      return needQuote ? `"${escaped}"` : escaped
    })
    .join(',')
}

/** 触发浏览器下载（添加 UTF-8 BOM，确保 Excel 不乱码） */
function downloadBlob(filename: string, content: string): void {
  const BOM = '\uFEFF'
  const blob = new Blob([BOM + content], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

/** 下载指定业态的导入模板（传入 'mixed' 下载综合体示例模板） */
export function downloadUnitImportTemplate(propertyType: PropertyType | 'mixed'): void {
  const spec = TEMPLATES[propertyType]
  const lines: string[] = []
  lines.push(toCsvLine(spec.headers))
  for (const h of spec.hints) lines.push(h)
  for (const row of spec.sampleRows) lines.push(toCsvLine(row))
  downloadBlob(spec.filename, lines.join('\n'))
}
