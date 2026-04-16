import { promises as fs } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const appRoot = path.resolve(scriptDir, '..')
const srcRoot = path.join(appRoot, 'src')

const SCAN_EXTENSIONS = new Set(['.vue', '.ts', '.scss'])
const ALLOWLIST = new Set([
  'src/constants/theme.ts',
  'src/styles/tokens.scss',
  'src/uni.scss',
])

const IGNORE_MARKER = 'theme-guard-ignore-line'

const RULES = [
  {
    id: 'hex-color-literal',
    description: '禁止在页面或业务组件中直接写十六进制颜色，请改用主题 token 或 CSS 变量。',
    test: (line) => /(^|["'(\s:,=])#[0-9a-fA-F]{3,8}\b/.test(line),
  },
  {
    id: 'rgba-color-literal',
    description: '禁止在页面或业务组件中直接写 rgba/rgb 数值颜色，请改用主题 token。',
    test: (line) => /rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+(?:\s*,\s*(?:\d*\.?\d+|\d+%))?\s*\)/i.test(line),
  },
  {
    id: 'font-family-literal',
    description: '禁止在页面或业务组件中直接写 font-family，请改用 var(--theme-font-family-*)。',
    test: (line) => line.includes('font-family:') && !line.includes('var(--theme-font-family-'),
  },
  {
    id: 'inline-style-literal',
    description: '禁止在模板内通过 style 字面量写颜色或字体，请落到 class/token。',
    test: (line) => /\bstyle\s*=\s*["'][^"']*(?:font-family\s*:|#[0-9a-fA-F]{3,8}\b|rgba?\()/i.test(line),
  },
  {
    id: 'bound-inline-style-literal',
    description: '禁止在 :style 中直接写颜色或字体字面量，请落到 class/token。',
    test: (line) => /:\s*style\s*=\s*["'][^"']*(?:fontFamily\s*:|font-family\s*:|#[0-9a-fA-F]{3,8}\b|rgba?\()/i.test(line),
  },
  {
    id: 'component-color-prop-literal',
    description: '禁止组件 color 属性直接写字面量颜色，请传主题变量或 class。',
    test: (line) => /\bcolor\s*=\s*["'](?!var\(--|currentColor|inherit|transparent)[^"']+["']/.test(line),
  },
  {
    id: 'bound-color-prop-literal',
    description: '禁止 :color 绑定字符串字面量颜色，请传主题变量或 class。',
    test: (line) => /:\s*color\s*=\s*["'][^"']*(?:#[0-9a-fA-F]{3,8}\b|rgba?\(|['"][^'"]+['"])/i.test(line),
  },
  {
    id: 'font-family-object-literal',
    description: '禁止在对象样式中直接写 fontFamily，请改用主题变量。',
    test: (line) => /fontFamily\s*:\s*["'](?!var\(--theme-font-family-)[^"']+["']/.test(line),
  },
]

function shouldSkipLine(line) {
  const trimmed = line.trim()

  if (!trimmed) return true
  if (line.includes(IGNORE_MARKER)) return true
  if (trimmed.startsWith('//')) return true
  if (trimmed.startsWith('/*')) return true
  if (trimmed.startsWith('*')) return true
  if (trimmed.startsWith('<!--')) return true
  if (trimmed.startsWith('#endif') || trimmed.startsWith('#ifdef') || trimmed.startsWith('#ifndef')) return true

  return false
}

async function collectFiles(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true })
  const files = []

  for (const entry of entries) {
    if (entry.name === 'dist' || entry.name === 'node_modules') {
      continue
    }

    const absolutePath = path.join(directory, entry.name)

    if (entry.isDirectory()) {
      files.push(...await collectFiles(absolutePath))
      continue
    }

    if (SCAN_EXTENSIONS.has(path.extname(entry.name))) {
      files.push(absolutePath)
    }
  }

  return files
}

function findViolations(relativePath, content) {
  if (ALLOWLIST.has(relativePath)) {
    return []
  }

  const violations = []
  const lines = content.split(/\r?\n/)

  lines.forEach((line, index) => {
    if (shouldSkipLine(line)) {
      return
    }

    RULES.forEach((rule) => {
      if (rule.test(line)) {
        violations.push({
          file: relativePath,
          line: index + 1,
          rule: rule.id,
          description: rule.description,
          snippet: line.trim(),
        })
      }
    })
  })

  return violations
}

async function main() {
  const sourceFiles = await collectFiles(srcRoot)
  const violations = []

  for (const filePath of sourceFiles) {
    const relativePath = path.relative(appRoot, filePath).split(path.sep).join('/')
    const content = await fs.readFile(filePath, 'utf8')

    violations.push(...findViolations(relativePath, content))
  }

  if (violations.length === 0) {
    console.log('Theme guard passed: 未发现页面或业务组件中的颜色/字体硬编码。')
    return
  }

  console.error(`Theme guard failed: 发现 ${violations.length} 个违规点。`)

  for (const violation of violations) {
    console.error(`- ${violation.file}:${violation.line} [${violation.rule}] ${violation.description}`)
    console.error(`  ${violation.snippet}`)
  }

  console.error(`如确有必要，请把颜色落到 src/constants/theme.ts、src/styles/tokens.scss 或 src/uni.scss；单行豁免可添加注释 ${IGNORE_MARKER}。`)
  process.exitCode = 1
}

main().catch((error) => {
  console.error('Theme guard crashed:', error)
  process.exitCode = 1
})