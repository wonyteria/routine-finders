import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
