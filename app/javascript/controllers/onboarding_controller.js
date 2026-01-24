import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["step", "indicator"]
    static values = { currentStep: Number }

    connect() {
        this.showStep(this.currentStepValue)
    }

    nextStep() {
        if (this.currentStepValue < this.stepTargets.length - 1) {
            this.currentStepValue++
            this.showStep(this.currentStepValue)
        }
    }

    prevStep() {
        if (this.currentStepValue > 0) {
            this.currentStepValue--
            this.showStep(this.currentStepValue)
        }
    }

    showStep(stepIndex) {
        // Hide all steps
        this.stepTargets.forEach((step, index) => {
            if (index === stepIndex) {
                step.classList.remove("hidden")
                step.classList.add("animate-in", "fade-in", "slide-in-from-right-4")
            } else {
                step.classList.add("hidden")
                step.classList.remove("animate-in", "fade-in", "slide-in-from-right-4")
            }
        })

        // Update indicators
        this.indicatorTargets.forEach((indicator, index) => {
            if (index === stepIndex) {
                indicator.classList.remove("bg-slate-200")
                indicator.classList.add("bg-blue-600")
            } else {
                indicator.classList.remove("bg-blue-600")
                indicator.classList.add("bg-slate-200")
            }
        })
    }

    complete() {
        // Mark onboarding as completed via AJAX
        fetch('/complete_onboarding', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            }
        }).then(response => {
            if (response.ok) {
                // Close modal with animation
                this.element.classList.add("animate-out", "fade-out", "zoom-out")
                setTimeout(() => {
                    this.element.remove()
                }, 300)
            }
        })
    }
}
