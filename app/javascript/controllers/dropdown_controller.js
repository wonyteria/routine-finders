import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu"]

    connect() {
        this.isOpen = false
    }

    toggle(event) {
        if (event) {
            event.preventDefault()
            event.stopPropagation()
        }
        this.menuTarget.classList.toggle("hidden")
        this.isOpen = !this.menuTarget.classList.contains("hidden")
    }

    hide(event) {
        if (this.isOpen && !this.element.contains(event.target)) {
            this.menuTarget.classList.add("hidden")
            this.isOpen = false
        }
    }
}
