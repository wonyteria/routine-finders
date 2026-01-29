import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        console.log("SystemAdmin v2 Connected")
    }

    broadcast(event) {
        event.preventDefault()
        const title = window.prompt("긴급 공지 제목:")
        if (!title) return
        const content = window.prompt("공지 내용:")
        if (!content) return

        this.performPost('/prototype/admin/broadcast', { title, content })
    }

    promoteUser(event) {
        const userId = event.currentTarget.dataset.userId
        const nickname = event.currentTarget.dataset.nickname
        const currentRole = event.currentTarget.dataset.role
        const newRole = currentRole === 'user' ? 'club_admin' : 'super_admin'

        if (window.confirm(`${nickname}님을 ${newRole}(으)로 승격하시겠습니까?`)) {
            this.performPost('/prototype/admin/update_user_role', { user_id: userId, role: newRole }, true)
        }
    }

    deactivateUser(event) {
        const userId = event.currentTarget.dataset.userId
        const nickname = event.currentTarget.dataset.nickname

        if (window.confirm(`${nickname}님의 활성 상태를 변경하시겠습니까?`)) {
            this.performPost('/prototype/admin/toggle_user_status', { user_id: userId }, true)
        }
    }

    approveChallenge(event) {
        const challengeId = event.currentTarget.dataset.challengeId
        const title = event.currentTarget.dataset.title

        if (window.confirm(`'${title}' 챌린지를 승인하시겠습니까?`)) {
            this.performPost('/prototype/admin/approve_challenge', { challenge_id: challengeId }, true)
        }
    }

    deleteUser(event) {
        const userId = event.currentTarget.dataset.userId
        const nickname = event.currentTarget.dataset.nickname

        if (window.confirm(`${nickname}님과 모든 관련 데이터를 영구 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) {
            this.performDelete(`/prototype/admin/users/${userId}`, {}, true)
        }
    }

    deleteChallenge(event) {
        const challengeId = event.currentTarget.dataset.challengeId
        const title = event.currentTarget.dataset.title

        if (window.confirm(`'${title}' 챌린지를 영구 삭제하시겠습니까?`)) {
            this.performDelete(`/prototype/admin/challenges/${challengeId}`, {}, true)
        }
    }

    deleteClub(event) {
        const clubId = event.currentTarget.dataset.clubId
        const title = event.currentTarget.dataset.title

        if (window.confirm(`'${title}' 클럽을 영구 삭제하시겠습니까?`)) {
            this.performDelete(`/prototype/admin/clubs/${clubId}`, {}, true)
        }
    }

    purgeCache() {
        if (window.confirm("시스템 캐시를 전체 초기화하시겠습니까?")) {
            this.performPost('/prototype/admin/purge_cache', {})
        }
    }

    async performPost(url, body, reload = false) {
        this.performRequest(url, 'POST', body, reload)
    }

    async performDelete(url, body, reload = false) {
        this.performRequest(url, 'DELETE', body, reload)
    }

    async performRequest(url, method, body, reload = false) {
        try {
            const token = document.querySelector('meta[name="csrf-token"]')?.content
            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': token
                },
                body: JSON.stringify(body)
            })

            const data = await response.json()
            if (data.status === 'success') {
                this.notify(data.message, "emerald")
                if (reload) setTimeout(() => window.location.reload(), 1000)
            } else {
                this.notify(data.message || "오류 발생", "rose")
            }
        } catch (e) {
            console.error(e)
            this.notify("통신 오류", "rose")
        }
    }

    notify(msg, color) {
        const toast = document.createElement("div")
        toast.className = `fixed bottom-24 left-1/2 -translate-x-1/2 px-6 py-3 rounded-2xl bg-${color}-600 text-white text-[10px] font-black uppercase tracking-widest shadow-2xl z-[99999] animate-in fade-in slide-in-from-bottom-4 duration-300`
        toast.innerText = msg
        document.body.appendChild(toast)
        setTimeout(() => {
            toast.style.opacity = '0'
            toast.style.transition = 'opacity 0.3s'
            setTimeout(() => toast.remove(), 300)
        }, 3000)
    }

    comingSoon() {
        this.notify("준비 중인 기능입니다", "indigo")
    }
}
