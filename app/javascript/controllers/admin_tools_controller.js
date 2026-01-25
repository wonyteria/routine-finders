import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["title", "content"]

    async broadcast(event) {
        event.preventDefault()

        const title = prompt("공지 제목을 입력하세요:")
        if (!title) return

        const content = prompt("공지 내용을 입력하세요:")
        if (!content) return

        if (!confirm(`'${title}' 공지를 모든 사용자에게 발송하시겠습니까?`)) return

        try {
            const response = await fetch('/prototype/admin/broadcast', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ title: title, content: content })
            })

            const data = await response.json()
            if (data.status === 'success') {
                alert(data.message)
            } else {
                alert("발송 중 오류가 발생했습니다.")
            }
        } catch (error) {
            console.error(error)
            alert("서버 통신 오류가 발생했습니다.")
        }
    }

    comingSoon() {
        alert("준비 중인 기능입니다. 다음 업데이트를 기다려주세요! 🛠️")
    }
}
