import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('show_login') === 'true') {
            const modal = document.getElementById('login-modal')
            if (modal) {
                modal.classList.remove('hidden')
                document.body.classList.add('overflow-hidden')
            }
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
}
