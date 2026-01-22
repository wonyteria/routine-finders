import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="phone-format"
export default class extends Controller {
    static targets = ["input"]

    connect() {
        this.formatInput(this.element)
    }

    format(event) {
        const input = event.target
        this.formatInput(input)
    }

    formatInput(input) {
        const rawValue = input.value;

        // If input contains letters or URL-like characters, don't enforce numeric formatting
        if (/[a-zA-Z:\/\.]/.test(rawValue)) {
            return;
        }

        let value = rawValue.replace(/\D/g, "")
        let formattedValue = ""

        if (value.length > 0) {
            if (value.length <= 3) {
                formattedValue = value
            } else if (value.length <= 7) {
                formattedValue = value.slice(0, 3) + "-" + value.slice(3)
            } else if (value.length <= 11) {
                formattedValue = value.slice(0, 3) + "-" + value.slice(3, 7) + "-" + value.slice(7)
            } else {
                // Limit to 11 digits (typical Korean mobile number)
                value = value.slice(0, 11)
                formattedValue = value.slice(0, 3) + "-" + value.slice(3, 7) + "-" + value.slice(7)
            }
        }

        input.value = formattedValue
    }
}
