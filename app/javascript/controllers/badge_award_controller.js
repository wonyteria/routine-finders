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
        const duration = 1 * 1000 // 3초에서 1초로 단축
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
        }, 200) // 간격도 약간 단축
    }

    preventClosing(e) {
        e.stopPropagation()
    }

    handleBackdropClick(e) {
        this.finishAll(true) // 배경 클릭 시 로드맵으로 이동
    }

    // 다음 배지 보기 (모달 내 전환)
    next(e) {
        if (e) e.stopPropagation()

        const currentCard = this.containerTargets[this.currentIndex]
        currentCard.classList.add("opacity-0", "scale-95", "pointer-events-none")

        this.currentIndex++

        if (this.currentIndex < this.containerTargets.length) {
            setTimeout(() => {
                const nextCard = this.containerTargets[this.currentIndex]
                nextCard.classList.remove("opacity-0", "scale-90", "pointer-events-none")
                nextCard.classList.add("opacity-100", "scale-100")
                this.fireConfetti()
            }, 200)
        } else {
            this.finishAll(true)
        }
    }

    // 배지 로드맵으로 바로 가기
    goToRoadmap(e) {
        if (e) e.stopPropagation()
        this.finishAll(true)
    }

    close(e) {
        if (e) e.stopPropagation()
        this.next(e)
    }

    finishAll(redirectToRoadmap = true) {
        const overlay = document.getElementById("badge-award-overlay")
        if (!overlay) return

        overlay.classList.add("opacity-0")

        // 배지 확인 완료 처리 (서버 요청)
        const badgeIdsStr = this.element.getAttribute("data-badge-award-badge-ids")
        const badgeIds = JSON.parse(badgeIdsStr)

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
                if (redirectToRoadmap) {
                    window.location.href = "/badge_roadmap"
                } else {
                    window.location.reload()
                }
            }, 300)
        })
    }
}
