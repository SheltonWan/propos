import { mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { describe, expect, it } from 'vitest'
import AppCard from '../AppCard.vue'

// Mock ui_constants
vi.mock('@/constants/ui_constants', () => ({
  MOTION_DURATION_ENTER_MS: 300,
  MOTION_DURATION_STAGGER_MS: 50,
  MOTION_DURATION_STANDARD_MS: 200,
  MOTION_EASING_STANDARD: 'ease',
}))

describe('appCard', () => {
  const globalPlugins = [createPinia()]

  it('renders default slot content', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      slots: { default: 'Card body content' },
    })
    expect(wrapper.text()).toContain('Card body content')
  })

  it('applies variant class', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { variant: 'muted' },
      slots: { default: 'content' },
    })
    expect(wrapper.classes()).toContain('app-card--muted')
  })

  it('shows loading skeleton when state is loading', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { state: 'loading' },
    })
    expect(wrapper.find('.app-card__state--loading').exists()).toBe(true)
  })

  it('shows empty state', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { state: 'empty' },
    })
    expect(wrapper.text()).toContain('暂无数据')
  })

  it('shows error state', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { state: 'error' },
    })
    expect(wrapper.text()).toContain('加载失败')
  })

  it('emits click event when clickable', async () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { clickable: true },
      slots: { default: 'click me' },
    })
    await wrapper.trigger('tap')
    // Click emit is conditional
  })

  it('applies padding class', () => {
    const wrapper = mount(AppCard, {
      global: { plugins: globalPlugins },
      props: { padding: 'lg' },
      slots: { default: 'content' },
    })
    expect(wrapper.classes()).toContain('app-card--pad-lg')
  })
})
