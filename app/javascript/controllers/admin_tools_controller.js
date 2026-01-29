import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        console.log("SystemAdmin connected")
    }

    broadcast(event) {
        event.preventDefault()
        const title = prompt("긴급 공지 제목을 입력하세요:")
        if (!title) return
        const content = prompt("공지 내용을 입력하세요:")
        if (!content) return

        if (confirm(`'${title}' 공지를 모든 사용자에게 발송하시겠습니까?`)) {
            this.sendAction('/prototype/admin/broadcast', { title, content })
        }
    }

    promoteUser(event) {
        const btn = event.currentTarget
        const nickname = btn.dataset.nickname
        const userId = btn.dataset.userId
        const currentRole = btn.dataset.role
        const newRole = currentRole === 'user' ? 'club_admin' : 'super_admin'

        if (confirm(`${nickname}님의 권한을 ${newRole}(으)로 승격하시겠습니까?`)) {
            this.sendAction('/prototype/admin/update_user_role', { user_id: userId, role: newRole }, true)
        }
    }

    deactivateUser(event) {
        const btn = event.currentTarget
        const nickname = btn.dataset.nickname
        const userId = btn.dataset.userId

        if (confirm(`${nickname}님의 계정 상태를 변경하시겠습니까?`)) {
            this.sendAction('/prototype/admin/toggle_user_status', { user_id: userId }, true)
        }
    }

    approveChallenge(event) {
        const btn = event.currentTarget
        const challengeId = btn.dataset.challengeId
        const title = btn.dataset.title

        if (confirm(`'${title}' 챌린지를 승인하시겠습니까?`)) {
            this.sendAction('/prototype/admin/approve_challenge', { challenge_id: challengeId }, true)
        }
    }

    purgeCache() {
        if (confirm("모든 시스템 캐시를 초기화하시겠습니까?")) {
            this.sendAction('/prototype/admin/purge_cache', {})
        }
    }

    async sendAction(url, body, reload = false) {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify(body)
            })
            const data = await response.json()
            if (data.status === 'success') {
                this.showNotification(data.message, "emerald")
                if (reload) setTimeout(() => window.location.reload(), 1000)
            } else {
                this.showNotification(data.message || "오류가 발생했습니다.", "rose")
            }
        } catch (error) {
            console.error(error)
            this.showNotification("서버 통신 오류가 발생했습니다.", "rose")
        }
    }

    showNotification(message, color = "indigo") {
        const toast = document.createElement("div")
        toast.className = `fixed bottom-24 left-1/2 -translate-x-1/2 px-6 py-3 rounded-2xl bg-${color}-600 text-white text-[10px] font-black uppercase tracking-widest shadow-2xl z-[99999] animate-in fade-in slide-in-from-bottom-4 duration-300`
        toast.innerText = message
        document.body.appendChild(toast)
        setTimeout(() => {
            toast.classList.add("opacity-0")
            setTimeout(() => toast.remove(), 300)
        }, 3000)
    }

    comingSoon() {
        this.showNotification("준비 중인 기능입니다 🛠️")
    }
}
