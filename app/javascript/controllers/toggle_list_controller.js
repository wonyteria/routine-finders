import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["item", "button"]
    static values = { limit: Number }

    connect() {
        this.limit = this.hasLimitValue ? this.limitValue : 3
        this.showItems()
    }

    showItems() {
        this.itemTargets.forEach((item, index) => {
            if (index >= this.limit) {
                item.classList.add("hidden")
            } else {
                item.classList.remove("hidden")
            }
        })

        if (this.itemTargets.length <= this.limit) {
            this.buttonTarget.classList.add("hidden")
        }
    }

    showMore() {
        this.itemTargets.forEach(item => item.classList.remove("hidden"))
        this.buttonTarget.classList.add("hidden")
    }
}
