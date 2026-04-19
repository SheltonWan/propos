// eslint-disable-next-line ts/ban-ts-comment
// @ts-nocheck — uni-app 条件编译 (#ifdef) 指令在构建时由 vite-plugin-uni 处理，
// vue-tsc 无法解析，因此跳过此文件的类型检查。类型声明见 platform.d.ts。
/**
 * 平台适配统一入口
 *
 * 通过 uni-app 条件编译，在不同平台分别导出对应实现。
 */

// #ifdef APP-PLUS
export { applyThemeToDom, applyThemeToNative } from './theme-app'
// #endif

// #ifdef H5
export { applyThemeToDom, applyThemeToNative } from './theme-h5'
// #endif

// #ifndef H5 || APP-PLUS
// 其他平台（小程序等）提供空实现
export function applyThemeToDom(_vars: Record<string, string>): void {}
export function applyThemeToNative(_vars: Record<string, string>, _isDark: boolean): void {}
// #endif
