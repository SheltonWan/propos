import { ref } from 'vue'

type ToastType = 'success' | 'error' | 'warning' | 'info' | 'none'

interface ToastOptions {
  title: string
  type?: ToastType
  duration?: number
  mask?: boolean
}

const iconMap: Record<ToastType, 'success' | 'error' | 'none'> = {
  success: 'success',
  error: 'error',
  warning: 'none',
  info: 'none',
  none: 'none',
}

export function useToast() {
  const visible = ref(false)

  function show(options: ToastOptions) {
    const { title, type = 'none', duration = 2000, mask = false } = options
    visible.value = true
    uni.showToast({
      title,
      icon: iconMap[type],
      duration,
      mask,
    })
    setTimeout(() => {
      visible.value = false
    }, duration)
  }

  function success(title: string) {
    show({ title, type: 'success' })
  }

  function error(title: string) {
    show({ title, type: 'error' })
  }

  function warning(title: string) {
    show({ title, type: 'warning' })
  }

  function info(title: string) {
    show({ title, type: 'info' })
  }

  function hide() {
    uni.hideToast()
    visible.value = false
  }

  return { visible, show, success, error, warning, info, hide }
}
