import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["step", "indicator"]
    static values = { currentStep: { type: Number, default: 0 } }

    connect() {
        this.showStep(this.currentStepValue)
    }

    nextStep(event) {
        if (event) event.preventDefault()
        if (this.currentStepValue < this.stepTargets.length - 1) {
            this.currentStepValue++
            this.showStep(this.currentStepValue)
        }
    }

    prevStep(event) {
        if (event) event.preventDefault()
        if (this.currentStepValue > 0) {
            this.currentStepValue--
            this.showStep(this.currentStepValue)
        }
    }

    showStep(stepIndex) {
        // 1. 단계 전환 (숨김/표시 및 애니메이션)
        this.stepTargets.forEach((step, index) => {
            if (index === stepIndex) {
                step.classList.remove("hidden")
                step.classList.add("block", "animate-in", "fade-in", "slide-in-from-right-10", "duration-500")
            } else {
                step.classList.add("hidden")
                step.classList.remove("block", "animate-in", "fade-in", "slide-in-from-right-10", "duration-500")
            }
        })

        // 2. 인디케이터 업데이트 (활성화된 단계는 길게 표시)
        this.indicatorTargets.forEach((indicator, index) => {
            if (index === stepIndex) {
                indicator.className = "w-8 h-1 rounded-full bg-white transition-all duration-500"
            } else {
                indicator.className = "w-2 h-1 rounded-full bg-white/20 transition-all duration-500"
            }
        })
    }

    complete(event) {
        if (event) event.preventDefault()
        const button = event.currentTarget
        button.disabled = true
        button.innerHTML = '<span class="animate-pulse">입장 중...</span>'

        fetch('/complete_onboarding', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            }
        }).then(response => {
            if (response.ok) {
                this.element.classList.add("animate-out", "fade-out", "zoom-out-95", "duration-500")
                setTimeout(() => {
                    this.element.remove()
                }, 500)
            } else {
                button.disabled = false
                button.innerText = "다시 시도"
            }
        }).catch(() => {
            button.disabled = false
            button.innerText = "오류 발생"
        })
    }
}
