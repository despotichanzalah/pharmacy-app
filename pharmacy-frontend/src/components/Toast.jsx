import { useCallback, useState } from 'react'

export function useToast() {
  const [toast, setToast] = useState(null)

  const show = useCallback((message, kind = 'success') => {
    setToast({ message, kind })
    setTimeout(() => setToast(null), 3200)
  }, [])

  const ToastView = toast ? (
    <div className={`toast toast-${toast.kind}`}>{toast.message}</div>
  ) : null

  return { show, ToastView }
}
