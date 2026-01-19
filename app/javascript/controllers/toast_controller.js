import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    connect() {
        window.showToast = (message, type = "info") => this.show(message, type)
        this.checkFlash()
    }

    checkFlash() {
        // Read Rails flash messages from metadata or hidden elements
        const notice = document.querySelector('meta[name="flash-notice"]')?.content
        const alert = document.querySelector('meta[name="flash-alert"]')?.content

        if (notice) this.show(notice, "success")
        if (alert) this.show(alert, "error")
    }

    show(message, type = "info") {
        const toast = document.createElement("div")

        // Dynamic styles based on type
        const bgClass = {
            success: "bg-emerald-500",
            error: "bg-rose-500",
            info: "bg-indigo-600"
        }[type] || "bg-indigo-600"

        toast.className = `fixed bottom-24 left-1/2 -translate-x-1/2 z-[1000] px-6 py-3.5 rounded-2xl ${bgClass} text-white font-bold text-sm shadow-2xl animate-slide-up flex items-center gap-3`

        const icon = {
            success: "✨",
            error: "⚠️",
            info: "ℹ️"
        }[type] || "✨"

        toast.innerHTML = `
            <span>${icon}</span>
            <p>${message}</p>
        `

        document.body.appendChild(toast)

        // Fade out and remove
        setTimeout(() => {
            toast.classList.add("opacity-0", "translate-y-2")
            toast.classList.remove("animate-slide-up")
            toast.style.transition = "all 0.5s ease-in-out"
            setTimeout(() => toast.remove(), 500)
        }, 3000)
    }
}
