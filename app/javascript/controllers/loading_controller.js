import { Controller } from "@hotwired/stimulus"

// Loading Indicator Controller - Turbo 네비게이션 시 로딩 표시
export default class extends Controller {
    static targets = ["indicator"]

    connect() {
        // Turbo 이벤트 리스너 등록
        document.addEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
        document.addEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
        document.addEventListener("turbo:frame-load", this.hideLoading.bind(this))
    }

    disconnect() {
        document.removeEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
        document.removeEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
        document.removeEventListener("turbo:frame-load", this.hideLoading.bind(this))
    }

    showLoading() {
        if (this.hasIndicatorTarget) {
            this.indicatorTarget.classList.remove("hidden")
        } else {
            this.createIndicator()
        }
    }

    hideLoading() {
        if (this.hasIndicatorTarget) {
            this.indicatorTarget.classList.add("hidden")
        }
    }

    createIndicator() {
        const indicator = document.createElement("div")
        indicator.setAttribute("data-loading-target", "indicator")
        indicator.className = "fixed top-0 left-0 right-0 z-[9999] h-1 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500"
        indicator.innerHTML = `
      <div class="h-full bg-white/30 animate-pulse"></div>
    `
        document.body.appendChild(indicator)
    }
}
