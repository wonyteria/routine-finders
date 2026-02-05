import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    connect() {
        this.checkPopup()
    }

    checkPopup() {
        // Check if user has already seen and dismissed the popup
        const dismissed = localStorage.getItem("push_launch_popup_dismissed")

        // Also check if user has already enabled notifications (optional advanced check)
        // For now, simple check: if not dismissed, show it.
        if (!dismissed) {
            // Remove hidden class to show
            this.modalTarget.classList.remove("hidden")
            document.body.classList.add("overflow-hidden")
        }
    }

    close() {
        this.modalTarget.classList.add("hidden")
        document.body.classList.remove("overflow-hidden")
    }

    dontShowAgain() {
        localStorage.setItem("push_launch_popup_dismissed", "true")
        this.close()
    }

    goToSettings() {
        // Close modal first
        this.close()
        // The link_to in HTML handles navigation, but we can also store that they saw it
        // localStorage.setItem("push_launch_popup_dismissed", "true") // Optional: Mark as seen if they click Confirm
    }
}
