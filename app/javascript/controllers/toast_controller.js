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
        // Prevent duplicate toasts
        const existing = document.querySelector('.global-toast');
        if (existing) existing.remove();

        const toast = document.createElement("div")
        toast.className = "global-toast fixed inset-0 z-[100000] flex items-center justify-center p-8 pointer-events-none"

        const iconConfigs = {
            success: { icon: "✨", bg: "bg-emerald-500", shadow: "shadow-emerald-500/40" },
            error: { icon: "⚠️", bg: "bg-rose-500", shadow: "shadow-rose-500/40" },
            info: { icon: "ℹ️", bg: "bg-indigo-600", shadow: "shadow-indigo-600/40" }
        }
        const config = iconConfigs[type] || iconConfigs.info

        toast.innerHTML = `
            <div class="relative w-full max-w-sm bg-[#16151D]/90 backdrop-blur-2xl border border-white/10 p-10 rounded-[48px] shadow-[0_40px_100px_rgba(0,0,0,0.8)] flex flex-col items-center text-center space-y-6 animate-center-pop pointer-events-auto">
                <div class="w-24 h-24 ${config.bg} rounded-[32px] flex items-center justify-center text-5xl shadow-2xl ${config.shadow} mb-2 animate-bounce-subtle">
                    ${config.icon}
                </div>
                <div class="space-y-2">
                    <p class="text-lg font-black text-white leading-tight">${message.replace(/\n/g, '<br>')}</p>
                    <p class="text-xs font-bold text-slate-500 uppercase tracking-widest">${type === 'success' ? 'Completed' : 'System Message'}</p>
                </div>
            </div>
        `

        document.body.appendChild(toast)
        document.body.classList.add('overflow-hidden') // Lock background scrolling optionally

        // Automatic dismissal
        setTimeout(() => {
            const inner = toast.querySelector('div');
            if (inner) {
                inner.classList.add('opacity-0', 'scale-95');
                inner.style.transition = "all 0.5s cubic-bezier(0.16, 1, 0.3, 1)";
            }
            setTimeout(() => {
                toast.remove();
                if (!document.querySelector('.global-toast') && !document.querySelector('.fixed.inset-0:not(.hidden)')) {
                    document.body.classList.remove('overflow-hidden');
                }
            }, 500);
        }, 3000)
    }
}
