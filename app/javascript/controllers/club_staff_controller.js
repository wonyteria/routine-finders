import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    connect() {
        console.log("Club Staff Controller connected")
    }

    openModal(event) {
        event.preventDefault()
        this.modalTarget.classList.remove("hidden")
        this.modalTarget.classList.add("flex")
    }

    closeModal() {
        this.modalTarget.classList.add("hidden")
        this.modalTarget.classList.remove("flex")
    }

    async assignRole(event) {
        const userId = event.currentTarget.dataset.userId
        const nickname = event.currentTarget.dataset.nickname

        if (window.confirm(`${nickname}님께 '모더레이터' 역할을 부여하시겠습니까?`)) {
            await this.performRequest('/prototype/admin/update_user_role', 'POST', {
                user_id: userId,
                role: 'club_admin'
            })
        }
    }

    async removeRole(event) {
        const userId = event.currentTarget.dataset.userId
        const nickname = event.currentTarget.dataset.nickname

        if (window.confirm(`${nickname}님의 스태프 권한을 회수하시겠습니까?`)) {
            await this.performRequest('/prototype/admin/update_user_role', 'POST', {
                user_id: userId,
                role: 'user'
            })
        }
    }

    async performRequest(url, method, body) {
        const token = document.querySelector('meta[name="csrf-token"]')?.content
        try {
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
                window.location.reload()
            } else {
                alert(data.message || "오류가 발생했습니다.")
            }
        } catch (error) {
            console.error(error)
            alert("통신 중 오류가 발생했습니다.")
        }
    }
}
