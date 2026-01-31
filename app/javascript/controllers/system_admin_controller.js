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

        this.performPost('/admin_center/broadcast', { title, content })
    }

    updateUserRoleSelect(event) {
        const select = event.currentTarget
        const userId = select.dataset.userId
        const nickname = select.dataset.nickname
        const initialRole = select.dataset.initialValue
        const newRole = select.value
        const label = select.options[select.selectedIndex].text

        if (window.confirm(`${nickname}님의 권한을 '${label}'(으)로 변경하시겠습니까?`)) {
            this.performPost('/admin_center/update_user_role', { user_id: userId, role: newRole }, true)
        } else {
            // 취소 시 이전 값으로 복구
            select.value = initialRole
        }
    }

    updateUserStatusSelect(event) {
        const select = event.currentTarget
        const userId = select.dataset.userId
        const nickname = select.dataset.nickname
        const initialStatus = select.dataset.initialValue
        const newStatus = select.value
        const label = select.options[select.selectedIndex].text

        if (window.confirm(`${nickname}님의 상태를 '${label}'(으)로 변경하시겠습니까?`)) {
            this.performPost('/admin_center/update_user_status', { user_id: userId, status: newStatus }, true)
        } else {
            select.value = initialStatus
        }
    }

    approveChallenge(event) {
        const challengeId = event.currentTarget.dataset.challengeId
        const title = event.currentTarget.dataset.title

        if (window.confirm(`'${title}' 챌린지를 승인하시겠습니까?`)) {
            this.performPost('/admin_center/approve_challenge', { challenge_id: challengeId }, true)
        }
    }

    deleteContent(event) {
        const id = event.currentTarget.dataset.id
        const title = event.currentTarget.dataset.title

        if (window.confirm(`'${title}'을(를) 영구 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) {
            fetch(`/admin_center/delete_content/${id}`, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                    'Content-Type': 'application/json'
                }
            })
                .then(res => res.json())
                .then(data => {
                    if (data.status === 'success') {
                        alert(data.message)
                        window.location.reload()
                    } else {
                        alert(data.message || '삭제에 실패했습니다.')
                    }
                })
        }
    }

    notifyHost(event) {
        const id = event.currentTarget.dataset.id
        const nickname = event.currentTarget.dataset.nickname
        const title = event.currentTarget.dataset.title

        const message = window.prompt(`${nickname}님께 보낼 공지 내용을 입력해주세요.`, `'${title}' 관련 관리자 안내입니다.`)

        if (message) {
            this.performPost(`/admin_center/notify_host/${id}`, { content: message }, true)
        }
    }

    editContentPrompt(event) {
        // Prototype simplification: only title edit for now
        const id = event.currentTarget.dataset.id
        const title = event.currentTarget.dataset.title

        const newTitle = window.prompt(`수정할 제목을 입력해주세요. (데모용 단순 제목 수정)`, title)

        if (newTitle && newTitle !== title) {
            // Reusing a general update logic if exists, or adding it to PrototypeController
            this.performPost('/admin_center/update_content_basic', { id: id, title: newTitle }, true)
        }
    }

    purgeCache() {
        if (window.confirm("시스템 캐시를 전체 초기화하시겠습니까?")) {
            this.performPost('/admin_center/purge_cache', {})
        }
    }

    async performPost(url, body, reload = false) {
        try {
            const token = document.querySelector('meta[name="csrf-token"]')?.content
            const response = await fetch(url, {
                method: 'POST',
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
