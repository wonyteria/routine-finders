import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["banner"]
    static values = {
        storageKey: { type: String, default: "pwa_banner_dismissed" }
    }

    connect() {
        console.log('PWA Banner Controller connected');
        console.log('Storage key:', this.storageKeyValue);
        console.log('Dismissed?', localStorage.getItem(this.storageKeyValue));

        if (localStorage.getItem(this.storageKeyValue)) {
            console.log('Banner was dismissed, keeping hidden');
            this.bannerTarget.classList.add("hidden")
        } else {
            console.log('Showing banner after 1 second delay');
            // Subtle delay before showing to feel less intrusive
            setTimeout(() => {
                console.log('Removing hidden class and showing banner');
                this.bannerTarget.classList.remove("hidden")
                this.bannerTarget.classList.add("block", "animate-slide-up")
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
