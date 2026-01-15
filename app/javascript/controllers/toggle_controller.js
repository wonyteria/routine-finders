import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "indicator"]

    connect() {
        this.isOn = false
    }

    switch() {
        this.isOn = !this.isOn

        if (this.isOn) {
            // Turn ON
            this.buttonTarget.classList.remove("justify-end")
            this.buttonTarget.classList.add("justify-start", "bg-indigo-500")
            this.indicatorTarget.classList.remove("bg-slate-600")
            this.indicatorTarget.classList.add("bg-white")
        } else {
            // Turn OFF
            this.buttonTarget.classList.remove("justify-start", "bg-indigo-500")
            this.buttonTarget.classList.add("justify-end")
            this.indicatorTarget.classList.remove("bg-white")
            this.indicatorTarget.classList.add("bg-slate-600")
        }
    }
}
