import { beforeEach, describe, expect, it } from 'vitest'
import {
  consumeIntendedTabPath,
  setIntendedTabPath,
} from '../navigationIntent'

describe('navigationIntent', () => {
  beforeEach(() => {
    // Consume any leftover intent
    consumeIntendedTabPath()
  })

  it('setIntendedTabPath + consumeIntendedTabPath round-trip', () => {
    setIntendedTabPath('/pages/dashboard/index')
    expect(consumeIntendedTabPath()).toBe('/pages/dashboard/index')
  })

  it('consumeIntendedTabPath returns null when no intent set', () => {
    expect(consumeIntendedTabPath()).toBeNull()
  })

  it('consumes only once — second call returns null', () => {
    setIntendedTabPath('/pages/assets/index')
    expect(consumeIntendedTabPath()).toBe('/pages/assets/index')
    expect(consumeIntendedTabPath()).toBeNull()
  })

  it('overwriting intent before consume uses latest value', () => {
    setIntendedTabPath('/pages/dashboard/index')
    setIntendedTabPath('/pages/workorders/index')
    expect(consumeIntendedTabPath()).toBe('/pages/workorders/index')
  })
})
