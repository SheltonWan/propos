export type AppTabBarItemId = 'dashboard' | 'assets' | 'contracts' | 'workorders' | 'finance'

export interface AppTabBarItem {
  id: AppTabBarItemId
  text: string
  pagePath: string
}

interface IconPalette {
  active: boolean
  activeColor: string
  inactiveColor: string
  surfaceColor: string
}

const SVG_NS = 'http://www.w3.org/2000/svg'

export const APP_TABBAR_ITEMS: AppTabBarItem[] = [
  { id: 'dashboard', text: '首页', pagePath: '/pages/dashboard/index' },
  { id: 'assets', text: '资产', pagePath: '/pages/assets/index' },
  { id: 'contracts', text: '合同', pagePath: '/pages/contracts/index' },
  { id: 'workorders', text: '工单', pagePath: '/pages/workorders/index' },
  { id: 'finance', text: '财务', pagePath: '/pages/finance/index' },
]

function createSvgDataUri(markup: string) {
  return `data:image/svg+xml;utf8,${encodeURIComponent(markup)}`
}

function resolveColors(palette: IconPalette) {
  return {
    iconColor: palette.active ? palette.activeColor : palette.inactiveColor,
    contrastColor: palette.surfaceColor,
  }
}

function renderDashboardIcon(palette: IconPalette) {
  const { iconColor } = resolveColors(palette)

  const content = palette.active
    ? `
      <rect x="10" y="10" width="18" height="18" rx="5" fill="${iconColor}" />
      <rect x="36" y="10" width="18" height="18" rx="5" fill="${iconColor}" opacity="0.78" />
      <rect x="10" y="36" width="18" height="18" rx="5" fill="${iconColor}" opacity="0.72" />
      <rect x="36" y="36" width="18" height="18" rx="5" fill="${iconColor}" />
    `
    : `
      <rect x="10" y="10" width="18" height="18" rx="5" fill="none" stroke="${iconColor}" stroke-width="4" />
      <rect x="36" y="10" width="18" height="18" rx="5" fill="none" stroke="${iconColor}" stroke-width="4" />
      <rect x="10" y="36" width="18" height="18" rx="5" fill="none" stroke="${iconColor}" stroke-width="4" />
      <rect x="36" y="36" width="18" height="18" rx="5" fill="none" stroke="${iconColor}" stroke-width="4" />
    `

  return `<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="${SVG_NS}">${content}</svg>`
}

function renderAssetsIcon(palette: IconPalette) {
  const { iconColor } = resolveColors(palette)

  const content = `
      <path d="M6 22V4C6 2.895 6.895 2 8 2H16C17.105 2 18 2.895 18 4V22" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M6 12H4C2.895 12 2 12.895 2 14V20C2 21.105 2.895 22 4 22H6" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M18 9H20C21.105 9 22 9.895 22 11V20C22 21.105 21.105 22 20 22H18" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M10 6H14" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M10 10H14" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M10 14H14" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M10 18H14" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
    `

  return `<svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="${SVG_NS}">${content}</svg>`
}

function renderContractsIcon(palette: IconPalette) {
  const { iconColor, contrastColor } = resolveColors(palette)

  const content = palette.active
    ? `
      <path d="M22 10H38L48 20V50C48 52.209 46.209 54 44 54H22C19.791 54 18 52.209 18 50V14C18 11.791 19.791 10 22 10Z" fill="${iconColor}" />
      <path d="M38 10V20H48" fill="${contrastColor}" opacity="0.95" />
      <path d="M26 28H40M26 36H40M26 44H35" stroke="${contrastColor}" stroke-width="4" stroke-linecap="round" />
    `
    : `
      <path d="M38 10H22C19.791 10 18 11.791 18 14V50C18 52.209 19.791 54 22 54H44C46.209 54 48 52.209 48 50V20L38 10Z" fill="none" stroke="${iconColor}" stroke-width="4" stroke-linejoin="round" />
      <path d="M38 10V20H48" fill="none" stroke="${iconColor}" stroke-width="4" stroke-linejoin="round" />
      <path d="M26 28H40M26 36H40M26 44H35" stroke="${iconColor}" stroke-width="4" stroke-linecap="round" />
    `

  return `<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="${SVG_NS}">${content}</svg>`
}

function renderWorkordersIcon(palette: IconPalette) {
  const { iconColor, contrastColor } = resolveColors(palette)

  const content = palette.active
    ? `
      <rect x="18" y="16" width="28" height="38" rx="6" fill="${iconColor}" />
      <rect x="25" y="10" width="14" height="10" rx="4" fill="${contrastColor}" />
      <path d="M24 36L29 41L40 30" stroke="${contrastColor}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" />
    `
    : `
      <rect x="18" y="16" width="28" height="38" rx="6" fill="none" stroke="${iconColor}" stroke-width="4" />
      <rect x="25" y="10" width="14" height="10" rx="4" fill="none" stroke="${iconColor}" stroke-width="4" />
      <path d="M24 36L29 41L40 30" stroke="${iconColor}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" />
    `

  return `<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="${SVG_NS}">${content}</svg>`
}

function renderFinanceIcon(palette: IconPalette) {
  const { iconColor, contrastColor } = resolveColors(palette)

  const content = palette.active
    ? `
      <rect x="16" y="16" width="32" height="32" rx="8" fill="${iconColor}" />
      <rect x="24" y="30" width="4" height="10" rx="2" fill="${contrastColor}" />
      <rect x="30" y="24" width="4" height="16" rx="2" fill="${contrastColor}" />
      <rect x="36" y="20" width="4" height="20" rx="2" fill="${contrastColor}" />
    `
    : `
      <rect x="16" y="16" width="32" height="32" rx="8" fill="none" stroke="${iconColor}" stroke-width="4" />
      <path d="M24 40V30M32 40V24M40 40V20" stroke="${iconColor}" stroke-width="4" stroke-linecap="round" />
    `

  return `<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="${SVG_NS}">${content}</svg>`
}

const TABBAR_ICON_RENDERERS: Record<AppTabBarItemId, (palette: IconPalette) => string> = {
  dashboard: renderDashboardIcon,
  assets: renderAssetsIcon,
  contracts: renderContractsIcon,
  workorders: renderWorkordersIcon,
  finance: renderFinanceIcon,
}

const iconSrcCache = new Map<string, string>()

export function getTabBarIconSrc(itemId: AppTabBarItemId, palette: IconPalette) {
  const cacheKey = `${itemId}|${palette.active}|${palette.activeColor}|${palette.inactiveColor}|${palette.surfaceColor}`
  const cached = iconSrcCache.get(cacheKey)
  if (cached !== undefined) {
    return cached
  }
  const result = createSvgDataUri(TABBAR_ICON_RENDERERS[itemId](palette))
  iconSrcCache.set(cacheKey, result)
  return result
}
