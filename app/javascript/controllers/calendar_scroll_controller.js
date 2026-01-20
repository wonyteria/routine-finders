import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "today"]

    connect() {
        this.scrollToToday()
    }

    scrollToToday() {
        if (this.hasTodayTarget) {
            // Scroll the container so today is in view
            // We want some padding/context, so we scroll to a bit before today if possible
            const container = this.containerTarget
            const today = this.todayTarget

            const scrollOffset = today.offsetLeft - (container.offsetWidth / 2) + (today.offsetWidth / 2)
            container.scrollTo({
                left: scrollOffset,
                behavior: "smooth"
            })
        }
    }
}
