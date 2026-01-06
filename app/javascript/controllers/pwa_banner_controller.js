import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["banner"]
    static values = {
        storageKey: { type: String, default: "pwa_banner_dismissed" }
    }

    connect() {
        if (localStorage.getItem(this.storageKeyValue)) {
            this.bannerTarget.classList.add("hidden")
        } else {
            // Subtle delay before showing to feel less intrusive
            setTimeout(() => {
                this.bannerTarget.classList.remove("hidden")
                this.bannerTarget.classList.add("animate-slide-up")
            }, 1000)
        }
    }

    dismiss() {
        this.bannerTarget.classList.add("animate-slide-out-down")
        setTimeout(() => {
            this.bannerTarget.classList.add("hidden")
        }, 500)
    }

    dismissForever() {
        localStorage.setItem(this.storageKeyValue, "true")
        this.dismiss()
    }
}
