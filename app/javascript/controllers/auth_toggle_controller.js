import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["social", "emailForm"]

    showEmail() {
        this.socialTarget.classList.add("hidden")
        this.emailFormTarget.classList.remove("hidden")
    }

    showSocial() {
        this.emailFormTarget.classList.add("hidden")
        this.socialTarget.classList.remove("hidden")
    }
}
