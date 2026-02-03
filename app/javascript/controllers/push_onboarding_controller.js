import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    dismiss() {
        this.hideModal()
        this.sendDismissToServer()
    }

    showSetup() {
        this.hideModal()
        // Redirect to my page with hash to trigger setup if needed, 
        // or just let them find it. The user requested "설정을 하라는 공지"
        window.location.href = "/prototype/my"
    }

    hideModal() {
        this.modalTarget.classList.add("hidden")
    }

    async sendDismissToServer() {
        try {
            await fetch('/pwa/dismiss_notice', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                }
            })
        } catch (error) {
            console.error('Failed to dismiss push notice:', error)
        }
    }
}
