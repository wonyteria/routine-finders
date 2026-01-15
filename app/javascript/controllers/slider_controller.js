import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["output", "input"]

    connect() {
        // Initialize the output with the current input value
        if (this.hasOutputTarget && this.hasInputTarget) {
            this.outputTarget.textContent = this.inputTarget.value + "%"
        }
    }

    update(event) {
        if (this.hasOutputTarget && this.hasInputTarget) {
            this.outputTarget.textContent = this.inputTarget.value + "%"
        }
    }
}
