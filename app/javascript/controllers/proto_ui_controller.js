import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('show_login') === 'true') {
            window.location.href = '/prototype/login'
        }
    }

    openModal(event) {
        const modalId = event.currentTarget.dataset.modalId
        const modal = document.getElementById(modalId)
        if (modal) {
            modal.classList.remove('hidden')
            document.body.classList.add('overflow-hidden')
        }
    }

    closeModal(event) {
        const modal = event.currentTarget.closest('[data-modal-target="container"]') || event.currentTarget.closest('.fixed')
        if (modal) {
            modal.classList.add('hidden')
            document.body.classList.remove('overflow-hidden')
        }
    }

    checkLogin(event) {
        // We use data-logged-in on body to check status
        const isLoggedIn = document.body.getAttribute('data-logged-in')

        if (isLoggedIn === "false") {
            // Stop current action
            event.preventDefault()
            event.stopImmediatePropagation()

            // Redirect to dedicated login page
            // This ensures a "move" to the login state as requested
            window.location.href = '/prototype/login'
            return false
        }
        return true
    }
}
