import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    connect() {
        this.currentIndex = 0
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
        const currentCard = this.containerTargets[this.currentIndex]
        currentCard.classList.add("opacity-0", "scale-95", "pointer-events-none")

        this.currentIndex++

        if (this.currentIndex < this.containerTargets.length) {
            // 다음 배지가 있으면 보여주기
            setTimeout(() => {
                const nextCard = this.containerTargets[this.currentIndex]
                nextCard.classList.remove("opacity-0", "scale-90", "pointer-events-none")
                nextCard.classList.add("opacity-100", "scale-100")
                this.fireConfetti()
            }, 500)
        } else {
            // 모든 배지를 확인했으면 오버레이 제거 및 새로고침
            const overlay = document.getElementById("badge-award-overlay")
            overlay.classList.add("opacity-0")

            // 배지 확인 완료 처리 (서버 요청)
            const badgeIds = JSON.parse(this.data.get("badgeIds"))
            fetch("/mark_badges_viewed", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ badge_ids: badgeIds })
            }).then(() => {
                setTimeout(() => {
                    overlay.remove()
                    window.location.reload() // 원래 화면으로 확실히 돌아가기 위해 새로고침
                }, 500)
            })
        }
    }
}
