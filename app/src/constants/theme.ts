export const THEME_STORAGE_KEY = 'propos_theme_id'

export const BODY_FONT_FAMILY = "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
export const DISPLAY_FONT_FAMILY = "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"

export type ThemeId = 'apple' | 'emerald' | 'violet' | 'rose' | 'amber' | 'dark'

export interface ThemePreset {
  id: ThemeId
  name: string
  swatches: [string, string, string]
  vars: Record<string, string>
}

interface ThemePalette {
  primary: string
  surfaceLight: string
  background: string
  foreground: string
  backgroundDark: string
  foregroundDark: string
  muted: string
  mutedForeground: string
  mutedDark: string
  mutedForegroundDark: string
  border: string
  borderDark: string
  success: string
  warning: string
  destructive: string
  info: string
}

const PRIMARY_FOREGROUND = '#ffffff'
const MASK_COLOR = 'rgba(0, 0, 0, 0.32)'
const DISABLED_MASK_COLOR = 'rgba(255, 255, 255, 0.48)'
const SURFACE_OVERLAY_COLOR = 'rgba(255, 255, 255, 0.16)'
const HANDLE_COLOR = 'rgba(0, 0, 0, 0.12)'
const SKELETON_BASE_COLOR = 'rgba(0, 0, 0, 0.05)'
const SKELETON_HIGHLIGHT_COLOR = 'rgba(255, 255, 255, 0.72)'

function hexToRgbString(hex: string): string {
  const normalized = hex.replace('#', '')
  const fullHex = normalized.length === 3
    ? normalized.split('').map((char) => `${char}${char}`).join('')
    : normalized

  const red = Number.parseInt(fullHex.slice(0, 2), 16)
  const green = Number.parseInt(fullHex.slice(2, 4), 16)
  const blue = Number.parseInt(fullHex.slice(4, 6), 16)

  return `${red}, ${green}, ${blue}`
}

function withAlpha(hex: string, alpha: number): string {
  return `rgba(${hexToRgbString(hex)}, ${alpha})`
}

function buildThemeVars(palette: ThemePalette): Record<string, string> {
  return {
    '--theme-font-family-body': BODY_FONT_FAMILY,
    '--theme-font-family-display': DISPLAY_FONT_FAMILY,
    '--color-primary': palette.primary,
    '--color-primary-foreground': PRIMARY_FOREGROUND,
    '--color-surface-light': palette.surfaceLight,
    '--color-background': palette.background,
    '--color-foreground': palette.foreground,
    '--color-background-dark': palette.backgroundDark,
    '--color-foreground-dark': palette.foregroundDark,
    '--color-muted': palette.muted,
    '--color-muted-foreground': palette.mutedForeground,
    '--color-muted-dark': palette.mutedDark,
    '--color-muted-foreground-dark': palette.mutedForegroundDark,
    '--color-border': palette.border,
    '--color-border-dark': palette.borderDark,
    '--color-mask': MASK_COLOR,
    '--color-disabled-mask': DISABLED_MASK_COLOR,
    '--color-skeleton-base': SKELETON_BASE_COLOR,
    '--color-skeleton-highlight': SKELETON_HIGHLIGHT_COLOR,
    '--color-success': palette.success,
    '--color-warning': palette.warning,
    '--color-destructive': palette.destructive,
    '--color-info': palette.info,
    '--color-primary-soft': withAlpha(palette.primary, 0.05),
    '--color-primary-focus-ring': withAlpha(palette.primary, 0.15),
    '--color-primary-disabled': withAlpha(palette.primary, 0.6),
    '--color-muted-soft': withAlpha(palette.muted, 0.3),
    '--color-muted-strong': withAlpha(palette.muted, 0.5),
    '--color-muted-foreground-soft': withAlpha(palette.mutedForeground, 0.6),
    '--color-destructive-soft': withAlpha(palette.destructive, 0.08),
    '--color-destructive-border-soft': withAlpha(palette.destructive, 0.15),
    '--color-surface-overlay': SURFACE_OVERLAY_COLOR,
    '--color-handle': HANDLE_COLOR,
  }
}

export const DEFAULT_THEME_ID: ThemeId = 'apple'

export const THEME_PRESETS: ThemePreset[] = [
  {
    id: 'apple',
    name: 'Apple Blue',
    swatches: ['#0071e3', '#ffffff', '#1c1c1e'],
    vars: buildThemeVars({
      primary: '#0071e3',
      surfaceLight: '#f5f5f7',
      background: '#ffffff',
      foreground: '#1d1d1f',
      backgroundDark: '#1c1c1e',
      foregroundDark: '#f5f5f7',
      muted: '#ececf0',
      mutedForeground: '#717182',
      mutedDark: '#2c2c2e',
      mutedForegroundDark: '#98989d',
      border: 'rgba(0, 0, 0, 0.1)',
      borderDark: 'rgba(255, 255, 255, 0.08)',
      success: '#34c759',
      warning: '#ff9f0a',
      destructive: '#d4183d',
      info: '#5856d6',
    }),
  },
  {
    id: 'emerald',
    name: '森林绿',
    swatches: ['#059669', '#ffffff', '#064e3b'],
    vars: buildThemeVars({
      primary: '#059669',
      surfaceLight: '#ecfdf5',
      background: '#ffffff',
      foreground: '#064e3b',
      backgroundDark: '#064e3b',
      foregroundDark: '#d1fae5',
      muted: '#d1fae5',
      mutedForeground: '#047857',
      mutedDark: '#065f46',
      mutedForegroundDark: '#a7f3d0',
      border: 'rgba(5, 150, 105, 0.15)',
      borderDark: 'rgba(209, 250, 229, 0.16)',
      success: '#16a34a',
      warning: '#d97706',
      destructive: '#dc2626',
      info: '#059669',
    }),
  },
  {
    id: 'violet',
    name: '优雅紫',
    swatches: ['#7c3aed', '#ffffff', '#4c1d95'],
    vars: buildThemeVars({
      primary: '#7c3aed',
      surfaceLight: '#f5f3ff',
      background: '#ffffff',
      foreground: '#4c1d95',
      backgroundDark: '#4c1d95',
      foregroundDark: '#ede9fe',
      muted: '#ede9fe',
      mutedForeground: '#6d28d9',
      mutedDark: '#5b21b6',
      mutedForegroundDark: '#c4b5fd',
      border: 'rgba(124, 58, 237, 0.15)',
      borderDark: 'rgba(237, 233, 254, 0.16)',
      success: '#16a34a',
      warning: '#d97706',
      destructive: '#dc2626',
      info: '#7c3aed',
    }),
  },
  {
    id: 'rose',
    name: '玫瑰红',
    swatches: ['#e11d48', '#ffffff', '#881337'],
    vars: buildThemeVars({
      primary: '#e11d48',
      surfaceLight: '#fff1f2',
      background: '#ffffff',
      foreground: '#881337',
      backgroundDark: '#881337',
      foregroundDark: '#ffe4e6',
      muted: '#ffe4e6',
      mutedForeground: '#be123c',
      mutedDark: '#9f1239',
      mutedForegroundDark: '#fda4af',
      border: 'rgba(225, 29, 72, 0.15)',
      borderDark: 'rgba(255, 228, 230, 0.16)',
      success: '#16a34a',
      warning: '#d97706',
      destructive: '#dc2626',
      info: '#e11d48',
    }),
  },
  {
    id: 'amber',
    name: '暖橙金',
    swatches: ['#d97706', '#ffffff', '#78350f'],
    vars: buildThemeVars({
      primary: '#d97706',
      surfaceLight: '#fffbeb',
      background: '#ffffff',
      foreground: '#78350f',
      backgroundDark: '#78350f',
      foregroundDark: '#fef3c7',
      muted: '#fef3c7',
      mutedForeground: '#b45309',
      mutedDark: '#92400e',
      mutedForegroundDark: '#fcd34d',
      border: 'rgba(217, 119, 6, 0.15)',
      borderDark: 'rgba(254, 243, 199, 0.18)',
      success: '#16a34a',
      warning: '#d97706',
      destructive: '#dc2626',
      info: '#d97706',
    }),
  },
  {
    id: 'dark',
    name: '深色模式',
    swatches: ['#2997ff', '#1c1c1e', '#000000'],
    vars: buildThemeVars({
      primary: '#2997ff',
      surfaceLight: '#1c1c1e',
      background: '#1c1c1e',
      foreground: '#f5f5f7',
      backgroundDark: '#000000',
      foregroundDark: '#ffffff',
      muted: '#2c2c2e',
      mutedForeground: '#98989d',
      mutedDark: '#3a3a3c',
      mutedForegroundDark: '#d1d1d6',
      border: 'rgba(255, 255, 255, 0.1)',
      borderDark: 'rgba(255, 255, 255, 0.12)',
      success: '#30d158',
      warning: '#ffd60a',
      destructive: '#ff453a',
      info: '#5e5ce6',
    }),
  },
]

export function isThemeId(value: string): value is ThemeId {
  return THEME_PRESETS.some((preset) => preset.id === value)
}

export function getThemePreset(themeId: ThemeId): ThemePreset {
  return THEME_PRESETS.find((preset) => preset.id === themeId) ?? THEME_PRESETS[0]
}