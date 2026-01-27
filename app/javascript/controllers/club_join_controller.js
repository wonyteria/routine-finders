import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form", "depositorInput", "contactInput", "threadsInput", "goalInput",
        "confirmModal", "confirmName", "confirmContact", "confirmThreads", "confirmGoal"]

    review(event) {
        event.preventDefault()

        // Fill confirm modal with current values
        this.confirmNameTarget.textContent = this.depositorInputTarget.value || "-"
        this.confirmContactTarget.textContent = this.contactInputTarget.value || "-"
        this.confirmThreadsTarget.textContent = this.threadsInputTarget.value || "-"
        this.confirmGoalTarget.textContent = this.goalInputTarget.value || "-"

        // Show modal
        this.confirmModalTarget.classList.remove("hidden")
        document.body.classList.add("overflow-hidden")
    }

    close() {
        this.confirmModalTarget.classList.add("hidden")
        document.body.classList.remove("overflow-hidden")
    }

    submit() {
        this.formTarget.submit()
    }
}
