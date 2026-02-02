import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    connect() {
        window.showToast = (message, type = "info") => this.show(message, type)
        this.checkFlash()
        this.checkAuthError()
    }

    checkAuthError() {
        const urlParams = new URLSearchParams(window.location.search)
        const authError = urlParams.get('auth_error')
        const strategy = urlParams.get('strategy')

        if (authError) {
            let message = `인증 오류가 발생했습니다 (${authError})`
            if (strategy === 'kakao') {
                message = "카카오 로그인 중 오류가 발생했습니다. 카카오 개발자 설정 또는 계정 상태를 확인해 주세요."
            }
            this.show(message, "error")

            // Remove auth_error from URL without reloading
            const url = new URL(window.location.href)
            url.searchParams.delete('auth_error')
            url.searchParams.delete('strategy')
            window.history.replaceState({}, document.title, url.toString())
        }
    }

    checkFlash() {
        // Read Rails flash messages from metadata or hidden elements
        const notice = document.querySelector('meta[name="flash-notice"]')?.content
        const alert = document.querySelector('meta[name="flash-alert"]')?.content

        if (notice) this.show(notice, "success")
        if (alert) this.show(alert, "error")
    }

    show(message, type = "info") {
        const toast = document.createElement("div")

        // Dynamic styles based on type
        const bgClass = {
            success: "bg-emerald-500",
            error: "bg-rose-500",
            info: "bg-indigo-600"
        }[type] || "bg-indigo-600"

        toast.className = `fixed top-1/2 left-1/2 z-[100000] px-8 py-5 rounded-[32px] ${bgClass} text-white font-black text-sm shadow-[0_20px_60px_rgba(0,0,0,0.5)] animate-toast-pop flex flex-col items-center gap-4 min-w-[280px] text-center backdrop-blur-xl border border-white/20`

        const icon = {
            success: "✨",
            error: "⚠️",
            info: "ℹ️"
        }[type] || "✨"

        toast.innerHTML = `
            <span>${icon}</span>
            <p>${message.replace(/\n/g, '<br>')}</p>
        `

        document.body.appendChild(toast)

        // Fade out and remove
        setTimeout(() => {
            toast.classList.add("opacity-0", "translate-y-2")
            toast.classList.remove("animate-slide-up")
            toast.style.transition = "all 0.5s ease-in-out"
            setTimeout(() => toast.remove(), 500)
        }, 3000)
    }
}
