import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('show_login') === 'true') {
            window.location.href = '/login'
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

    toggleFabMenu() {
        const menu = document.getElementById('fab-menu-sheet')
        const content = menu.querySelector('.relative.bg-\\[\\#1B1A24\\]')
        const bg = menu.querySelector('.absolute.inset-0.bg-black\\/80')

        if (menu.classList.contains('hidden')) {
            // Open
            menu.classList.remove('hidden')
            bg.style.opacity = '0'
            content.style.transform = 'translateY(100%)'

            requestAnimationFrame(() => {
                bg.style.transition = 'opacity 0.3s ease'
                content.style.transition = 'transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)'
                bg.style.opacity = '1'
                content.style.transform = 'translateY(0)'
            })
            document.body.classList.add('overflow-hidden')
        } else {
            // Close
            bg.style.opacity = '0'
            content.style.transform = 'translateY(100%)'

            setTimeout(() => {
                menu.classList.add('hidden')
                document.body.classList.remove('overflow-hidden')
                // Reset styles
                content.style.transform = ''
                bg.style.opacity = ''
            }, 300)
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
            window.location.href = '/login'
            return false
        }
        return true
    }
}
