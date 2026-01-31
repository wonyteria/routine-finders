import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "indicator", "content", "icon"]

    connect() {
        // Detect initial state from classes
        this.isOn = this.buttonTarget?.classList.contains("justify-end")
    }

    switch() {
        this.isOn = !this.isOn

        if (this.isOn) {
            // Turn ON (Right)
            this.buttonTarget.classList.remove("justify-start", "bg-slate-800")
            this.buttonTarget.classList.add("justify-end", "bg-indigo-500")
            this.indicatorTarget.classList.remove("bg-slate-600")
            this.indicatorTarget.classList.add("bg-white")
        } else {
            // Turn OFF (Left)
            this.buttonTarget.classList.remove("justify-end", "bg-indigo-500")
            this.buttonTarget.classList.add("justify-start", "bg-slate-800")
            this.indicatorTarget.classList.remove("bg-white")
            this.indicatorTarget.classList.add("bg-slate-600")
        }
    }

    toggle() {
        if (this.hasContentTarget) {
            this.contentTarget.classList.toggle("hidden")
        }
        if (this.hasIconTarget) {
            this.iconTarget.classList.toggle("rotate-180")
        }
    }
}
