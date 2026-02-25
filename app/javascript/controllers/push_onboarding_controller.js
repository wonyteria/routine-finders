import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
        this.element.classList.add("hidden")
    }

    async sendDismissToServer() {
        try {
            const csrfTokenElem = document.querySelector('meta[name="csrf-token"]')
            const csrfToken = csrfTokenElem ? csrfTokenElem.content : ''
            await fetch('/pwa/dismiss_notice', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken
                }
            })
        } catch (error) {
            console.error('Failed to dismiss push notice:', error)
        }
    }
}
