import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    connect() {
        if (this.hasContainerTarget) {
            this.fireConfetti()
        }
    }

    fireConfetti() {
        const duration = 3 * 1000
        const animationEnd = Date.now() + duration
        const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 9999 }

        const randomInRange = (min, max) => Math.random() * (max - min) + min

        const interval = setInterval(() => {
            const timeLeft = animationEnd - Date.now()

            if (timeLeft <= 0) {
                return clearInterval(interval)
            }

            const particleCount = 50 * (timeLeft / duration)

            confetti({
                ...defaults,
                particleCount,
                origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 }
            })
            confetti({
                ...defaults,
                particleCount,
                origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 }
            })
        }, 250)
    }

    close() {
        this.containerTarget.classList.add("opacity-0", "scale-95")
        setTimeout(() => {
            this.containerTarget.remove()
            // 배지 확인 완료 처리 (서버 요청)
            const badgeIds = JSON.parse(this.data.get("badgeIds"))
            fetch("/mark_badges_viewed", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ badge_ids: badgeIds })
            })
        }, 500)
    }
}
