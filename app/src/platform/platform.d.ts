/**
 * 平台适配模块类型声明
 *
 * platform/index.ts 使用 uni-app 条件编译 (#ifdef)，vue-tsc 无法解析，
 * 此文件为 TypeScript 提供模块签名。
 */
declare module '@/platform/index' {
  /** 将主题 CSS 变量注入到当前平台的 DOM */
  export function applyThemeToDom(vars: Record<string, string>): void
  /** 在原生层设置主题相关属性（如背景色、状态栏样式） */
  export function applyThemeToNative(vars: Record<string, string>, isDark: boolean): void
}
