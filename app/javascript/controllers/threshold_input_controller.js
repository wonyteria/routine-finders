import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        min: Number,
        max: Number
    }

    connect() {
        // Enforce limits on initial load
        this.enforce()
    }

    enforce(event) {
        let value = parseInt(this.element.value) || 0

        // Clamp value between min and max
        if (value < this.minValue) {
            value = this.minValue
        } else if (value > this.maxValue) {
            value = this.maxValue
        }

        this.element.value = value
    }

    // Prevent non-numeric input
    preventInvalid(event) {
        const key = event.key
        const currentValue = this.element.value

        // Allow: backspace, delete, tab, escape, enter
        if ([
            'Backspace', 'Delete', 'Tab', 'Escape', 'Enter',
            'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'
        ].includes(key)) {
            return
        }

        // Allow: Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X
        if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(key.toLowerCase())) {
            return
        }

        // Prevent if not a number
        if (!/^\d$/.test(key)) {
            event.preventDefault()
            return
        }

        // Check if the resulting value would exceed max
        const newValue = parseInt(currentValue + key) || 0
        if (newValue > this.maxValue) {
            event.preventDefault()
        }
    }
}
// Force reload
