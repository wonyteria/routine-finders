import { Controller } from "@hotwired/stimulus"

// Lazy Loading Controller - 이미지 지연 로딩으로 초기 페이지 로드 속도 개선
export default class extends Controller {
    static targets = ["image"]

    connect() {
        this.observer = new IntersectionObserver(
            (entries) => this.handleIntersection(entries),
            {
                rootMargin: "50px", // 뷰포트에 들어오기 50px 전에 로드 시작
                threshold: 0.01
            }
        )

        this.imageTargets.forEach((image) => {
            this.observer.observe(image)
        })
    }

    disconnect() {
        if (this.observer) {
            this.observer.disconnect()
        }
    }

    handleIntersection(entries) {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                const image = entry.target
                const src = image.dataset.lazySrc

                if (src) {
                    // 이미지 로드
                    image.src = src
                    image.removeAttribute("data-lazy-src")

                    // 로딩 완료 시 페이드인 효과
                    image.addEventListener("load", () => {
                        image.classList.add("loaded")
                    })

                    // 관찰 중지
                    this.observer.unobserve(image)
                }
            }
        })
    }
}
