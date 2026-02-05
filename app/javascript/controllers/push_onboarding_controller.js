import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    dismiss() {
        this.hideModal()
        this.sendDismissToServer()
    }

    showSetup() {
        this.hideModal()
        // Anchor to the specific settings section
        window.location.href = "/prototype/my#push-settings-section"
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
