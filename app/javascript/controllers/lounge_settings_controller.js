import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["liveInput", "lectureInput", "liveContainer", "lectureContainer", "liveToggle", "lectureToggle"]

    connect() {
        this.toggleLive()
        this.toggleLecture()
    }

    toggleLive() {
        const isActive = this.liveToggleTarget.checked
        this.liveInputTargets.forEach(input => {
            input.disabled = !isActive
            if (!isActive) {
                input.classList.add("opacity-40", "cursor-not-allowed")
            } else {
                input.classList.remove("opacity-40", "cursor-not-allowed")
            }
        })

        if (!isActive) {
            this.liveContainerTarget.classList.add("grayscale-[0.5]")
        } else {
            this.liveContainerTarget.classList.remove("grayscale-[0.5]")
        }
    }

    toggleLecture() {
        const isActive = this.lectureToggleTarget.checked
        this.lectureInputTargets.forEach(input => {
            input.disabled = !isActive
            if (!isActive) {
                input.classList.add("opacity-40", "cursor-not-allowed")
            } else {
                input.classList.remove("opacity-40", "cursor-not-allowed")
            }
        })

        if (!isActive) {
            this.lectureContainerTarget.classList.add("grayscale-[0.5]")
        } else {
            this.lectureContainerTarget.classList.remove("grayscale-[0.5]")
        }
    }
}
