/**
 * 公开页面白名单（无需登录即可访问）
 */
export const PUBLIC_PAGES = [
  '/pages/auth/login',
  '/pages/auth/change-password',
] as const

export function isPublicPage(path: string): boolean {
  const clean = path.split('?')[0]
  return PUBLIC_PAGES.includes(clean as typeof PUBLIC_PAGES[number])
}
