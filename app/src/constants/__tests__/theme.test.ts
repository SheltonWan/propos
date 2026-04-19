import { describe, expect, it } from 'vitest'
import {
  DEFAULT_THEME_ID,
  getThemePreset,
  isThemeId,
  THEME_PRESETS,
} from '../theme'

describe('theme constants', () => {
  it('dEFAULT_THEME_ID is a valid theme', () => {
    expect(isThemeId(DEFAULT_THEME_ID)).toBe(true)
  })

  it('isThemeId validates correctly', () => {
    expect(isThemeId('apple')).toBe(true)
    expect(isThemeId('dark')).toBe(true)
    expect(isThemeId('emerald')).toBe(true)
    expect(isThemeId('nonexistent')).toBe(false)
    expect(isThemeId('')).toBe(false)
  })

  it('getThemePreset returns matching preset', () => {
    const preset = getThemePreset('violet')
    expect(preset.id).toBe('violet')
    expect(preset.name).toBe('优雅紫')
  })

  it('getThemePreset falls back to first preset for invalid id', () => {
    const preset = getThemePreset('apple')
    expect(preset).toBe(THEME_PRESETS[0])
  })

  it('all presets have required vars', () => {
    const requiredVars = [
      '--color-primary',
      '--color-background',
      '--color-foreground',
      '--color-surface-light',
      '--color-border',
      '--color-success',
      '--color-warning',
      '--color-destructive',
    ]

    for (const preset of THEME_PRESETS) {
      for (const varName of requiredVars) {
        expect(preset.vars, `${preset.id} missing ${varName}`).toHaveProperty(varName)
        expect(preset.vars[varName], `${preset.id} ${varName} is empty`).toBeTruthy()
      }
    }
  })

  it('all presets have valid swatches', () => {
    for (const preset of THEME_PRESETS) {
      expect(preset.swatches).toHaveLength(3)
      for (const swatch of preset.swatches) {
        expect(swatch).toMatch(/^#[0-9a-fA-F]{6}$|^rgba?\(/)
      }
    }
  })

  it('presets have unique ids', () => {
    const ids = THEME_PRESETS.map(p => p.id)
    expect(new Set(ids).size).toBe(ids.length)
  })
})
